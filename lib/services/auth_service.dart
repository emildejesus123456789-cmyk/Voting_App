// lib/services/auth_service.dart
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

    // Sign in anonymously — creates a stable identity stored in Supabase
    final response = await _client.auth.signInAnonymously();
    if (response.user == null) {
      throw Exception('Failed to create anonymous user session');
    }
    return response.user!;
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  bool get isSignedIn => _client.auth.currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}