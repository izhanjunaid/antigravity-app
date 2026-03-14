import 'package:ibex_app/core/models/user_model.dart';
import 'package:ibex_app/core/supabase/supabase_client.dart';

class UserService {
  final _client = SupabaseClientHelper.client;

  /// Fetches the current user's profile.
  Future<UserModel?> getCurrentUser() async {
    final userId = SupabaseClientHelper.auth.currentUser?.id;
    if (userId == null) return null;
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  /// Fetches a user by ID.
  Future<UserModel?> getUserById(String id) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  /// Fetches all users with a specific role.
  Future<List<UserModel>> getUsersByRole(String role) async {
    final response = await _client
        .from('users')
        .select()
        .eq('role', role)
        .order('name');
    return response.map((e) => UserModel.fromJson(e)).toList();
  }

  /// Updates the current user's profile.
  Future<void> updateProfile({String? name, String? profilePic}) async {
    final userId = SupabaseClientHelper.auth.currentUser?.id;
    if (userId == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (profilePic != null) updates['profile_pic'] = profilePic;
    if (updates.isNotEmpty) {
      await _client.from('users').update(updates).eq('id', userId);
    }
  }

  /// Fetches the count of users by role.
  Future<int> countByRole(String role) async {
    final response = await _client.from('users').select('id').eq('role', role);
    return response.length;
  }
}
