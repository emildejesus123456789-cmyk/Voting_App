// lib/screens/results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/room.dart';
import '../models/voting_option.dart';
import '../models/irv_result.dart';
import '../widgets/app_widgets.dart';

class ResultsScreen extends StatelessWidget {
  final Room room;
  final List<VotingOption> options;
  final IrvResult result;

  const ResultsScreen({
    super.key,
    required this.room,
    required this.options,
    required this.result,
  });

  Map<String, String> get _labelMap =>
      {for (final o in options) o.id: o.label};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      icon: const Icon(Icons.home_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        room.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const StatusPill(isOpen: false),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _WinnerCard(result: result),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _StatChip(
                            label: 'Total Votes',
                            value: '${result.totalBallots}',
                            icon: Icons.how_to_vote_rounded,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            label: 'Rounds',
                            value: '${result.rounds.length}',
                            icon: Icons.loop_rounded,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            label: 'Exhausted',
                            value: '${result.exhaustedCount}',
                            icon: Icons.do_not_disturb_alt_rounded,
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 28),
                      Text(
                        'Round-by-Round Breakdown',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 4),
                      Text(
                        'IRV eliminates the weakest option each round until a majority winner emerges.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.slate500, fontSize: 13),
                      ).animate().fadeIn(delay: 370.ms),
                      const SizedBox(height: 16),
                      ...result.rounds.asMap().entries.map((entry) {
                        final i = entry.key;
                        final round = entry.value;
                        return _RoundCard(round: round, labelMap: _labelMap)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 400 + i * 100))
                            .slideY(
                                begin: 0.1,
                                delay: Duration(milliseconds: 400 + i * 100));
                      }),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  final IrvResult result;
  const _WinnerCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final winner = result.winner;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.amber400.withOpacity(0.15),
            AppTheme.amber600.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.amber400.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppTheme.amber400, size: 48),
          const SizedBox(height: 12),
          Text(
            'WINNER',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.amber400,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            winner?.label ?? 'No winner determined',
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(color: Colors.white, fontSize: 28),
            textAlign: TextAlign.center,
          ),
          if (result.rounds.isNotEmpty && winner != null) ...[
            const SizedBox(height: 8),
            Builder(builder: (ctx) {
              final lastRound = result.rounds.last;
              final winnerVotes = lastRound.tally[winner.id] ?? 0;
              final total = lastRound.totalVotes;
              final pct =
                  total > 0 ? (winnerVotes / total * 100).toStringAsFixed(1) : '0';
              return Text(
                '$winnerVotes votes ($pct%) in final round',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.amber400.withOpacity(0.7),
                    ),
              );
            }),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.92, 0.92), duration: 600.ms);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.navy600),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.slate500, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.slate500,
                    fontSize: 11,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  final IrvRound round;
  final Map<String, String> labelMap;
  const _RoundCard({required this.round, required this.labelMap});

  @override
  Widget build(BuildContext context) {
    final sortedEntries = round.tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: round.winner != null
              ? AppTheme.amber400.withOpacity(0.3)
              : AppTheme.navy600,
          width: round.winner != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: round.winner != null
                        ? AppTheme.amber400.withOpacity(0.15)
                        : AppTheme.navy700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Round ${round.round}',
                    style: TextStyle(
                      color: round.winner != null ? AppTheme.amber400 : AppTheme.slate300,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${round.totalVotes} votes',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.slate500, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: sortedEntries.map((entry) {
                final label = labelMap[entry.key] ?? entry.key;
                final votes = entry.value;
                final pct = round.totalVotes > 0 ? votes / round.totalVotes : 0.0;
                final isEliminated = entry.key == round.eliminated;
                final isWinner = entry.key == round.winner;
                final Color barColor = isWinner
                    ? AppTheme.amber400
                    : isEliminated
                        ? AppTheme.rose400
                        : AppTheme.slate500;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: isEliminated
                                          ? AppTheme.slate600
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      decoration: isEliminated
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isEliminated)
                                  const Icon(Icons.remove_circle_outline_rounded,
                                      color: AppTheme.rose400, size: 14),
                                if (isWinner)
                                  const Icon(Icons.emoji_events_rounded,
                                      color: AppTheme.amber400, size: 14),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$votes (${(pct * 100).toStringAsFixed(1)}%)',
                            style: TextStyle(
                                color: barColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          backgroundColor: AppTheme.navy700,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isEliminated
                                ? AppTheme.rose400.withOpacity(0.4)
                                : barColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          if (round.eliminated != null || round.winner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: round.winner != null
                      ? AppTheme.amber400.withOpacity(0.08)
                      : AppTheme.rose500.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      round.winner != null
                          ? Icons.emoji_events_rounded
                          : Icons.remove_circle_rounded,
                      size: 14,
                      color: round.winner != null ? AppTheme.amber400 : AppTheme.rose400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        round.winner != null
                            ? '${round.winnerLabel ?? round.winner} wins with a majority!'
                            : '${round.eliminatedLabel ?? round.eliminated} was eliminated — votes redistributed',
                        style: TextStyle(
                          color: round.winner != null ? AppTheme.amber400 : AppTheme.rose400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}