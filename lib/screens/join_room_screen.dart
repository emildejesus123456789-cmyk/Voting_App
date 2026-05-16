// lib/screens/join_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../widgets/app_widgets.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'voting_room_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room code must be 6 characters')),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate a stable ID from name + room code so the same person
      // rejoining gets the same ID, but different names get different IDs.
      // This lets multiple voters share the same device.
      final voterId = AuthService().voterIdForRoom(name: name, roomCode: code);

      final data = await ApiService().getRoom(code);

      if (!mounted) return;

      final hasVoted = await ApiService().checkHasVoted(code, voterId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VotingRoomScreen(
            room: data.room,
            options: data.options,
            isCreator: false,
            alreadyVoted: hasVoted,
            voterId: voterId,
            voterName: name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: 32),

                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: AppTheme.emerald500.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        // ignore: deprecated_member_use
                        color: AppTheme.emerald400.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.login_rounded,
                      color: AppTheme.emerald400, size: 36),
                ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 24),

                Text(
                  'Join a Room',
                  style: Theme.of(context).textTheme.displayMedium,
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 8),

                Text(
                  'Enter your name and the room code to cast your vote.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppTheme.slate500),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 32),

                // Name field
                Text(
                  'Your Name',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.slate300,
                        fontWeight: FontWeight.w600,
                      ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Alice',
                    prefixIcon:
                        Icon(Icons.person_rounded, color: AppTheme.slate500),
                  ),
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.words,
                ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // Room code field
                Text(
                  'Room Code',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.slate300,
                        fontWeight: FontWeight.w600,
                      ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    hintText: '······',
                    hintStyle: TextStyle(
                      color: AppTheme.slate600,
                      fontSize: 28,
                      letterSpacing: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                  ),
                  onChanged: (v) {
                    final upper = v.toUpperCase();
                    if (v != upper) {
                      _codeController.value = TextEditingValue(
                        text: upper,
                        selection:
                            TextSelection.collapsed(offset: upper.length),
                      );
                    }
                  },
                ).animate().fadeIn(delay: 330.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _joinRoom,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.navy900,
                          ),
                        )
                      : const Text('Join Room'),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const Spacer(),

                Center(
                  child: Text(
                    'Your name identifies you within this room',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.slate600, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}