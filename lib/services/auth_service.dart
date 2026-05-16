// lib/services/auth_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Returns the current user, signing in anonymously if needed.
  Future<User> getOrCreateUser() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) return currentUser;

    final response = await _client.auth.signInAnonymously();
    if (response.user == null) {
      throw Exception('Failed to create anonymous user session');
    }
    return response.user!;
  }

  /// Generates a stable, unique voter ID from a name + room code.
  /// Same name in the same room always gets the same ID —
  /// different names always get different IDs, even on the same device.
  String voterIdForRoom({required String name, required String roomCode}) {
    final input = '${name.trim().toLowerCase()}:${roomCode.toUpperCase()}';
    final hash = sha256.convert(utf8.encode(input));
    // Format as UUID-like string so it fits the text column cleanly
    final hex = hash.toString();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  bool get isSignedIn => _client.auth.currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}