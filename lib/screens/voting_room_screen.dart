// lib/screens/voting_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/room.dart';
import '../models/voting_option.dart';
import '../widgets/app_widgets.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'results_screen.dart';

class VotingRoomScreen extends StatefulWidget {
  final Room room;
  final List<VotingOption> options;
  final bool isCreator;
  final bool alreadyVoted;

  const VotingRoomScreen({
    super.key,
    required this.room,
    required this.options,
    this.isCreator = false,
    this.alreadyVoted = false,
  });

  @override
  State<VotingRoomScreen> createState() => _VotingRoomScreenState();
}

class _VotingRoomScreenState extends State<VotingRoomScreen> {
  late List<VotingOption> _rankedOptions;
  late Room _room;
  bool _hasVoted = false;
  bool _isSubmitting = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _rankedOptions = List.from(widget.options);
    _room = widget.room;
    _hasVoted = widget.alreadyVoted;
  }

  Future<void> _submitVote() async {
    setState(() => _isSubmitting = true);
    try {
      final userId = AuthService().currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final rankings = _rankedOptions.map((o) => o.id).toList();
      await ApiService().submitVote(
        roomCode: _room.code,
        userId: userId,
        rankings: rankings,
      );

      if (!mounted) return;

      setState(() => _hasVoted = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.emerald400),
              SizedBox(width: 10),
              Text('Vote submitted! Your ranking is locked in.'),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _closeVoting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Close Voting?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
          'This will end voting and calculate the winner using Instant Runoff Voting. This action cannot be undone.',
          style: TextStyle(color: AppTheme.slate300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.slate500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 44),
              backgroundColor: AppTheme.rose500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close & Count'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClosing = true);
    try {
      final userId = AuthService().currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final result = await ApiService().closeVotingAndGetResults(
        roomCode: _room.code,
        userId: userId,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            room: _room.copyWith(isOpen: false),
            options: widget.options,
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _room.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room code copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar area
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _room.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusPill(isOpen: _room.isOpen),
                  ],
                ),
              ),

              // Room code row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _copyCode,
                      child: RoomCodeChip(code: _room.code),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _copyCode,
                      child: const Icon(Icons.copy_rounded,
                          size: 18, color: AppTheme.slate500),
                    ),
                    const Spacer(),
                    if (widget.isCreator)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.amber400.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.amber400.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'CREATOR',
                          style: TextStyle(
                            color: AppTheme.amber400,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Instruction banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _hasVoted ? _votedBanner() : _instructionBanner(),
              ),

              const SizedBox(height: 12),

              // Options list
              Expanded(
                child: _hasVoted
                    ? _lockedRankingList()
                    : _draggableRankingList(),
              ),

              // Bottom actions
              Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_hasVoted && _room.isOpen)
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitVote,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.navy900),
                                )
                              : const Icon(Icons.how_to_vote_rounded),
                          label: const Text('Submit My Ranking'),
                        ),
                      if (widget.isCreator && _room.isOpen) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isClosing ? null : _closeVoting,
                          icon: _isClosing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.rose400),
                                )
                              : const Icon(Icons.lock_rounded,
                                  color: AppTheme.rose400),
                          label: const Text('Close Voting & Count',
                              style: TextStyle(color: AppTheme.rose400)),
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: AppTheme.rose400, width: 2),
                          ),
                        ),
                      ],
                      if (!_room.isOpen)
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.lock_rounded),
                          label: const Text('Voting is Closed'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.slate500,
                            side: const BorderSide(
                                color: AppTheme.slate600, width: 2),
                          ),
                        ),
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

  Widget _instructionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.navy700,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.navy600),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator_rounded,
              color: AppTheme.amber400, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Drag to rank your preferences — #1 is your top choice',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.slate300, fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _votedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.emerald500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.emerald400.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.emerald400, size: 18),
          const SizedBox(width: 10),
          Text(
            'Your vote has been submitted!',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.emerald400, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _draggableRankingList() {
    return ReorderableListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _rankedOptions.removeAt(oldIndex);
          _rankedOptions.insert(newIndex, item);
        });
      },
      proxyDecorator: (child, index, animation) => Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        color: AppTheme.surfaceLight,
        child: child,
      ),
      children: [
        for (int i = 0; i < _rankedOptions.length; i++)
          _OptionCard(
            key: ValueKey(_rankedOptions[i].id),
            option: _rankedOptions[i],
            rank: i + 1,
            draggable: true,
            isFirst: i == 0,
            dragIndex: i,
          ),
      ],
    );
  }

  Widget _lockedRankingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _rankedOptions.length,
      itemBuilder: (context, index) {
        final option = _rankedOptions[index];
        return _OptionCard(
          key: ValueKey(option.id),
          option: option,
          rank: index + 1,
          draggable: false,
          isFirst: index == 0,
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  final VotingOption option;
  final int rank;
  final bool draggable;
  final bool isFirst;
  // Required when draggable: the list index used by ReorderableDragStartListener.
  final int? dragIndex;

  const _OptionCard({
    super.key,
    required this.option,
    required this.rank,
    required this.draggable,
    required this.isFirst,
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context) {
    // The drag handle — only shown when draggable.
    // ReorderableDragStartListener ties it to the correct list index so that
    // only a press on the handle (not the whole card) initiates a drag.
    Widget? handle;
    if (draggable && dragIndex != null) {
      handle = ReorderableDragStartListener(
        index: dragIndex!,
        child: Padding(
          // Extra padding makes the touch target comfortably large.
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Icon(
            Icons.drag_handle_rounded,
            color: AppTheme.slate400,
            size: 26,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isFirst ? AppTheme.amber400.withOpacity(0.06) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFirst ? AppTheme.amber400.withOpacity(0.3) : AppTheme.navy600,
          width: isFirst ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            RankBadge(rank: rank),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isFirst ? Colors.white : AppTheme.slate300,
                          fontWeight:
                              isFirst ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                  if (rank == 1)
                    const Text(
                      'Your top choice',
                      style: TextStyle(
                        color: AppTheme.amber400,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (handle != null) handle,
          ],
        ),
      ),
    );
  }
}