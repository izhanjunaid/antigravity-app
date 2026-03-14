import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ibex_app/core/models/comment_model.dart';

class CommentService {
  final _supabase = Supabase.instance.client;
  static const String _table = 'comments';

  // Get comments for a stream post
  Future<List<CommentModel>> getPostComments(String postId) async {
    final response = await _supabase
        .from(_table)
        .select('*, users(name, role, profile_pic)')
        .eq('post_id', postId)
        .order('created_at');

    return (response as List).map((e) => CommentModel.fromJson(e)).toList();
  }

  // Get comments for a classwork item
  Future<List<CommentModel>> getClassworkComments(String classworkId) async {
    final response = await _supabase
        .from(_table)
        .select('*, users(name, role, profile_pic)')
        .eq('classwork_id', classworkId)
        .order('created_at');

    return (response as List).map((e) => CommentModel.fromJson(e)).toList();
  }

  // Listen to comments in realtime for a post
  Stream<List<CommentModel>> streamPostComments(String postId) {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at')
        .asyncMap((events) async {
          // In realtime streams we don't automatically get the joined table data
          // To get accurate user info for new realtime events, we need to fetch it explicitly.
          // Since it's realtime updates, we might have basic user info stored or we re-fetch the list
          
          // An alternative is re-fetching the full list with joins on change, 
          // but for basic demo, we will re-query the full list to ensure user data is joined.
          return getPostComments(postId);
        });
  }

  // Listen to comments in realtime for a classwork item
  Stream<List<CommentModel>> streamClassworkComments(String classworkId) {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('classwork_id', classworkId)
        .order('created_at')
        .asyncMap((events) async {
          return getClassworkComments(classworkId);
        });
  }

  // Add a comment
  Future<CommentModel> addComment({
    required String classId,
    String? postId,
    String? classworkId,
    required String content,
    String? parentId,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.from(_table).insert({
      'class_id': classId,
      'post_id': postId,
      'classwork_id': classworkId,
      'user_id': userId,
      'content': content,
      'parent_id': parentId,
    }).select('*, users(name, role, profile_pic)').single();

    return CommentModel.fromJson(response);
  }

  // Delete a comment
  Future<void> deleteComment(String commentId) async {
    await _supabase.from(_table).delete().eq('id', commentId);
  }
}
