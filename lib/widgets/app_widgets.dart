// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

/// A gradient background container
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.5, -0.7),
          radius: 1.2,
          colors: [Color(0xFF1A2540), AppTheme.navy900],
        ),
      ),
      child: child,
    );
  }
}

/// Amber accent card
class AccentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const AccentCard({super.key, required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.navy600, width: 1.5),
      ),
      child: child,
    );
  }
}

/// Large amber-accented text badge for rank indicator
class RankBadge extends StatelessWidget {
  final int rank;
  const RankBadge({super.key, required this.rank});

  Color get _badgeColor {
    if (rank == 1) return AppTheme.amber400;
    if (rank == 2) return AppTheme.slate500;
    return AppTheme.navy600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _badgeColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          color: _badgeColor,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Loading spinner with label
class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppTheme.amber400,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ]
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Room code display chip
class RoomCodeChip extends StatelessWidget {
  final String code;
  const RoomCodeChip({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.amber400.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.amber400.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.key_rounded, color: AppTheme.amber400, size: 16),
          const SizedBox(width: 8),
          Text(
            code,
            style: const TextStyle(
              color: AppTheme.amber400,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status pill — open / closed
class StatusPill extends StatelessWidget {
  final bool isOpen;
  const StatusPill({super.key, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? AppTheme.emerald500.withOpacity(0.15)
            : AppTheme.slate600.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen ? AppTheme.emerald400 : AppTheme.slate500,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOpen ? AppTheme.emerald400 : AppTheme.slate500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'VOTING OPEN' : 'VOTING CLOSED',
            style: TextStyle(
              color: isOpen ? AppTheme.emerald400 : AppTheme.slate500,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state widget
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.rose500.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppTheme.rose400, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}