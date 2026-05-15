// lib/screens/create_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../widgets/app_widgets.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'voting_room_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 options allowed')),
      );
      return;
    }
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 options are required')),
      );
      return;
    }
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in at least 2 options')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService().getOrCreateUser();
      final result = await ApiService().createRoom(
        title: _titleController.text.trim(),
        options: options,
        userId: user.id,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VotingRoomScreen(
            room: result.room,
            options: result.options,
            isCreator: true,
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
          child: Column(
            children: [
              // Header
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
                    Text(
                      'Create Room',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Room title
                        Text(
                          'Room Title',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppTheme.slate300,
                                fontWeight: FontWeight.w600,
                              ),
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Team lunch location vote',
                            prefixIcon: Icon(Icons.title_rounded,
                                color: AppTheme.slate500),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter a room title';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.sentences,
                        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                        const SizedBox(height: 28),

                        // Options header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Voting Options',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.slate300,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              '${_optionControllers.length}/10',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.slate500),
                            ),
                          ],
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 4),
                        Text(
                          'Participants will rank these from most to least preferred.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.slate600, fontSize: 12),
                        ).animate().fadeIn(delay: 220.ms),
                        const SizedBox(height: 12),

                        // Option fields
                        ...List.generate(_optionControllers.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                // Rank indicator
                                Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.navy700,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppTheme.navy600, width: 1),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: AppTheme.slate500,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _optionControllers[i],
                                    decoration: InputDecoration(
                                      hintText: 'Option ${i + 1}',
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Option cannot be empty';
                                      }
                                      return null;
                                    },
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                ),
                                // Remove button
                                if (_optionControllers.length > 2)
                                  IconButton(
                                    onPressed: () => _removeOption(i),
                                    icon: const Icon(Icons.remove_circle_outline_rounded),
                                    color: AppTheme.rose400,
                                    iconSize: 22,
                                  ),
                              ],
                            ),
                          ).animate().fadeIn(
                                delay: Duration(milliseconds: 250 + i * 50),
                              );
                        }),

                        // Add option button
                        TextButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add_rounded,
                              color: AppTheme.amber400),
                          label: const Text(
                            'Add Option',
                            style: TextStyle(color: AppTheme.amber400),
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 32),

                        // Submit button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _createRoom,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.navy900,
                                  ),
                                )
                              : const Text('Create Voting Room'),
                        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

                        const SizedBox(height: 32),
                      ],
                    ),
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