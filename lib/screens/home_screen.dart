// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../widgets/app_widgets.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Logo / Brand mark
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.amber400.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.amber400, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.how_to_vote_rounded,
                    color: AppTheme.amber400,
                    size: 28,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 500.ms)
                    .slideY(begin: -0.2, delay: 100.ms),

                const SizedBox(height: 32),

                // Headline
                Text(
                  'Ranked\nChoice\nVoting',
                  style: Theme.of(context).textTheme.displayLarge,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.1, delay: 200.ms),

                const SizedBox(height: 12),

                Text(
                  'Fair decisions through instant\nrunoff — every preference counts.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.slate500,
                      ),
                ).animate().fadeIn(delay: 350.ms, duration: 600.ms),

                const Spacer(),

                // Action cards
                _ActionCard(
                  icon: Icons.add_circle_rounded,
                  iconColor: AppTheme.amber400,
                  title: 'Create Voting Room',
                  subtitle: 'Set up a new ranked-choice vote',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 500.ms)
                    .slideY(begin: 0.15, delay: 500.ms),

                const SizedBox(height: 14),

                _ActionCard(
                  icon: Icons.login_rounded,
                  iconColor: AppTheme.emerald400,
                  title: 'Join Voting Room',
                  subtitle: 'Enter a room code to cast your vote',
                  outlined: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JoinRoomScreen()),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 500.ms)
                    .slideY(begin: 0.15, delay: 600.ms),

                const SizedBox(height: 48),

                // Footer
                Center(
                  child: Text(
                    'Powered by Instant Runoff Voting',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.slate600,
                          fontSize: 12,
                        ),
                  ),
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.transparent : AppTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: outlined ? AppTheme.navy600 : AppTheme.navy600,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.slate500),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}