/**
 * Instant Runoff Voting (IRV) Algorithm
 *
 * Given a list of ballots (each an ordered array of option IDs),
 * determines the winner via successive elimination rounds.
 */

/**
 * Run the full IRV algorithm.
 * @param {string[][]} ballots - Array of ballots; each ballot is an ordered array of option IDs.
 * @param {string[]} candidates - Array of all candidate option IDs.
 * @returns {{ winner: string|null, rounds: Round[], exhaustedCount: number }}
 */
function runIRV(ballots, candidates) {
  const rounds = [];
  let activeCandidates = new Set(candidates);
  let activeBallotsData = ballots.map((ranking) => ({ ranking, active: true }));

  // Validate: need at least 2 candidates and 1 ballot
  if (candidates.length < 2) {
    return { winner: candidates[0] ?? null, rounds: [], exhaustedCount: 0 };
  }

  let roundNumber = 1;

  while (true) {
    // Tally first-choice votes among active candidates
    const tally = {};
    for (const cand of activeCandidates) {
      tally[cand] = 0;
    }

    let exhaustedCount = 0;
    for (const ballotData of activeBallotsData) {
      const topChoice = getTopChoice(ballotData.ranking, activeCandidates);
      if (topChoice) {
        tally[topChoice] = (tally[topChoice] || 0) + 1;
      } else {
        exhaustedCount++;
      }
    }

    const totalVotes = Object.values(tally).reduce((a, b) => a + b, 0);

    // Build round snapshot
    const roundSnapshot = {
      round: roundNumber,
      tally: { ...tally },
      totalVotes,
      exhaustedCount,
      eliminated: null,
      winner: null,
    };

    // Check for majority winner (> 50%)
    for (const [cand, votes] of Object.entries(tally)) {
      if (votes > totalVotes / 2) {
        roundSnapshot.winner = cand;
        rounds.push(roundSnapshot);
        return { winner: cand, rounds, exhaustedCount };
      }
    }

    // Check if only one candidate remains
    if (activeCandidates.size === 1) {
      const lastCand = [...activeCandidates][0];
      roundSnapshot.winner = lastCand;
      rounds.push(roundSnapshot);
      return { winner: lastCand, rounds, exhaustedCount };
    }

    // Check for complete tie with no majority possible
    if (activeCandidates.size === 0) {
      rounds.push(roundSnapshot);
      return { winner: null, rounds, exhaustedCount };
    }

    // Find candidate(s) with the fewest votes to eliminate
    const minVotes = Math.min(...Object.values(tally));
    const toEliminate = Object.entries(tally)
      .filter(([, v]) => v === minVotes)
      .map(([k]) => k);

    // If all remaining candidates are tied, declare the one with most cumulative rank as winner
    if (toEliminate.length === activeCandidates.size) {
      // Complete tie — pick alphabetically as a deterministic tiebreaker
      const winner = [...activeCandidates].sort()[0];
      roundSnapshot.winner = winner;
      roundSnapshot.note = 'Complete tie — tiebreaker applied';
      rounds.push(roundSnapshot);
      return { winner, rounds, exhaustedCount };
    }

    // Eliminate the first tied candidate (deterministic: lowest ID alphabetically)
    const eliminated = toEliminate.sort()[0];
    roundSnapshot.eliminated = eliminated;
    rounds.push(roundSnapshot);

    activeCandidates.delete(eliminated);
    roundNumber++;
  }
}

/**
 * Get the top-ranked active candidate from a ballot.
 * @param {string[]} ranking - Ordered array of option IDs from most to least preferred.
 * @param {Set<string>} activeCandidates - Set of still-active candidate IDs.
 * @returns {string|null}
 */
function getTopChoice(ranking, activeCandidates) {
  for (const optionId of ranking) {
    if (activeCandidates.has(optionId)) {
      return optionId;
    }
  }
  return null; // Exhausted ballot
}

module.exports = { runIRV };