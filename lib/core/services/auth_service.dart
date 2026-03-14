import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ibex_app/core/models/user_model.dart';
import 'package:ibex_app/core/supabase/supabase_client.dart';

class AuthService {
  final _auth = SupabaseClientHelper.auth;
  final _client = SupabaseClientHelper.client;

  /// Signs in with email and password.
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) return null;
    return _fetchUserProfile(response.user!.id);
  }

  /// Signs up with email, password, name, and role.
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final response = await _auth.signUp(email: email, password: password);
    if (response.user == null) return null;

    // Insert into public.users table
    await _client.from('users').insert({
      'id': response.user!.id,
      'name': name,
      'email': email,
      'role': role,
    });

    return _fetchUserProfile(response.user!.id);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Returns the current session if one exists.
  Session? get currentSession => _auth.currentSession;

  /// Returns the current auth user's ID.
  String? get currentUserId => _auth.currentUser?.id;

  /// Fetches the user profile from the public.users table.
  Future<UserModel?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return _fetchUserProfile(userId);
  }

  Future<UserModel?> _fetchUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  /// Listens to auth state changes.
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
}
