const express = require('express');
const { body, param, validationResult } = require('express-validator');
const supabase = require('../supabaseClient');
const { runIRV } = require('../services/irvAlgorithm');

const router = express.Router();

function generateRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

// POST /api/rooms - Create a new voting room
router.post(
  '/',
  [
    body('title').trim().notEmpty().withMessage('Room title is required'),
    body('options').isArray({ min: 2 }).withMessage('At least 2 options are required'),
    body('options.*').trim().notEmpty().withMessage('Option labels cannot be empty'),
    body('userId').notEmpty().withMessage('User ID is required'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { title, options, userId } = req.body;

    // Generate unique room code
    let code;
    for (let attempts = 0; attempts < 10; attempts++) {
      code = generateRoomCode();
      const { data: existing } = await supabase
        .from('rooms')
        .select('id')
        .eq('code', code)
        .maybeSingle();
      if (!existing) break;
    }

    const roomId = require('crypto').randomUUID();
    const { data: room, error: roomError } = await supabase
      .from('rooms')
      .insert({
        id: roomId,
        title: title.trim(),
        code,
        createdby: userId,
        isopen: true,
      })
      .select()
      .single();

    if (roomError) {
      console.error('Room creation error:', roomError);
      return res.status(500).json({ error: 'Failed to create room', details: roomError.message });
    }

    const optionRows = options.map((label, index) => ({
      id: require('crypto').randomUUID(),
      roomid: roomId,
      label: label.trim(),
      position: index,
    }));

    const { data: insertedOptions, error: optionsError } = await supabase
      .from('options')
      .insert(optionRows)
      .select();

    if (optionsError) {
      console.error('Options creation error:', optionsError);
      await supabase.from('rooms').delete().eq('id', roomId);
      return res.status(500).json({ error: 'Failed to create options', details: optionsError.message });
    }

    res.status(201).json({ room, options: insertedOptions });
  }
);

// GET /api/rooms/:code - Get room by code
router.get('/:code', async (req, res) => {
  const { code } = req.params;

  const { data: room, error: roomError } = await supabase
    .from('rooms')
    .select('*')
    .eq('code', code.toUpperCase())
    .maybeSingle();

  if (roomError) {
    console.error('Room fetch error:', roomError);
    return res.status(500).json({ error: 'Failed to fetch room', details: roomError.message });
  }
  if (!room) {
    return res.status(404).json({ error: 'Room not found' });
  }

  const { data: options, error: optionsError } = await supabase
    .from('options')
    .select('*')
    .eq('roomid', room.id)
    .order('position');

  if (optionsError) {
    return res.status(500).json({ error: 'Failed to fetch options', details: optionsError.message });
  }

  const { count: voteCount } = await supabase
    .from('ballots')
    .select('*', { count: 'exact', head: true })
    .eq('roomid', room.id);

  res.json({ room, options: options || [], voteCount: voteCount || 0 });
});

// GET /api/rooms/:code/check-vote/:userId
router.get('/:code/check-vote/:userId', async (req, res) => {
  const { code, userId } = req.params;

  const { data: room } = await supabase
    .from('rooms')
    .select('id')
    .eq('code', code.toUpperCase())
    .maybeSingle();

  if (!room) {
    return res.status(404).json({ error: 'Room not found' });
  }

  const { data: ballot } = await supabase
    .from('ballots')
    .select('id')
    .eq('roomid', room.id)
    .eq('userid', userId)
    .maybeSingle();

  res.json({ hasVoted: !!ballot });
});

// POST /api/rooms/:code/close - Close voting and compute results
router.post('/:code/close', [body('userId').notEmpty()], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { code } = req.params;
  const { userId } = req.body;

  const { data: room, error: roomError } = await supabase
    .from('rooms')
    .select('*')
    .eq('code', code.toUpperCase())
    .maybeSingle();

  if (roomError) {
    return res.status(500).json({ error: 'Failed to fetch room', details: roomError.message });
  }
  if (!room) {
    return res.status(404).json({ error: 'Room not found' });
  }
  if (room.createdby !== userId) {
    return res.status(403).json({ error: 'Only the room creator can close voting' });
  }
  if (!room.isopen) {
    return res.status(400).json({ error: 'Voting is already closed' });
  }

  const { data: options, error: optionsError } = await supabase
    .from('options')
    .select('*')
    .eq('roomid', room.id)
    .order('position');

  if (optionsError || !options) {
    return res.status(500).json({ error: 'Failed to fetch options', details: optionsError?.message });
  }

  const { data: ballots, error: ballotsError } = await supabase
    .from('ballots')
    .select('rankings')
    .eq('roomid', room.id);

  if (ballotsError) {
    return res.status(500).json({ error: 'Failed to fetch ballots', details: ballotsError.message });
  }
  if (!ballots || ballots.length === 0) {
    return res.status(400).json({ error: 'No votes have been submitted yet' });
  }

  const candidateIds = options.map((o) => o.id);
  const rawBallots = ballots.map((b) => b.rankings);
  const { winner, rounds, exhaustedCount } = runIRV(rawBallots, candidateIds);

  const optionMap = {};
  for (const opt of options) {
    optionMap[opt.id] = opt.label;
  }

  const enrichedRounds = rounds.map((round) => ({
    ...round,
    tallyWithLabels: Object.fromEntries(
      Object.entries(round.tally).map(([id, count]) => [optionMap[id] || id, count])
    ),
    eliminatedLabel: round.eliminated ? optionMap[round.eliminated] : null,
    winnerLabel: round.winner ? optionMap[round.winner] : null,
  }));

  await supabase.from('rooms').update({ isopen: false }).eq('id', room.id);

  res.json({
    winner: winner ? { id: winner, label: optionMap[winner] } : null,
    rounds: enrichedRounds,
    totalBallots: ballots.length,
    exhaustedCount,
  });
});

module.exports = router;