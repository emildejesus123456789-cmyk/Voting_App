const express = require('express');
const { body, validationResult } = require('express-validator');
const supabase = require('../supabaseClient');

const router = express.Router();

// POST /api/votes - Submit a ballot
router.post(
  '/',
  [
    body('roomCode').trim().notEmpty().withMessage('Room code is required'),
    body('userId').notEmpty().withMessage('User ID is required'),
    body('rankings').isArray({ min: 1 }).withMessage('Rankings must be a non-empty array'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { roomCode, userId, rankings } = req.body;

    // Fetch room — maybeSingle returns null data (not an error) when no row found
    const { data: room, error: roomError } = await supabase
      .from('rooms')
      .select('id, isopen')
      .eq('code', roomCode.toUpperCase())
      .maybeSingle();

    if (roomError) {
      console.error('Room fetch error:', roomError);
      return res.status(500).json({ error: 'Failed to fetch room', details: roomError.message });
    }
    if (!room) {
      return res.status(404).json({ error: 'Room not found' });
    }
    if (!room.isopen) {
      return res.status(400).json({ error: 'Voting is closed for this room' });
    }

    // Check for duplicate ballot — maybeSingle so zero rows = null, not an error
    const { data: existing, error: existingError } = await supabase
      .from('ballots')
      .select('id')
      .eq('roomid', room.id)
      .eq('userid', userId)
      .maybeSingle();

    if (existingError) {
      console.error('Duplicate check error:', existingError);
      return res.status(500).json({ error: 'Failed to check existing vote', details: existingError.message });
    }
    if (existing) {
      return res.status(409).json({ error: 'You have already submitted a vote for this room' });
    }

    // Validate that all option IDs belong to this room
    const { data: options, error: optionsError } = await supabase
      .from('options')
      .select('id')
      .eq('roomid', room.id);

    if (optionsError || !options) {
      console.error('Options fetch error:', optionsError);
      return res.status(500).json({ error: 'Failed to fetch room options', details: optionsError?.message });
    }

    const validOptionIds = new Set(options.map((o) => o.id));
    const invalidOptions = rankings.filter((id) => !validOptionIds.has(id));

    if (invalidOptions.length > 0) {
      return res.status(400).json({ error: 'Invalid option IDs in rankings', invalidOptions });
    }

    // Insert ballot
    const { data: ballot, error: ballotError } = await supabase
      .from('ballots')
      .insert({
        id: require('crypto').randomUUID(),
        roomid: room.id,
        userid: userId,
        rankings,
      })
      .select()
      .single();

    if (ballotError) {
      console.error('Ballot insert error:', ballotError);
      return res.status(500).json({ error: 'Failed to submit ballot', details: ballotError.message });
    }

    res.status(201).json({ message: 'Vote submitted successfully', ballot });
  }
);

module.exports = router;