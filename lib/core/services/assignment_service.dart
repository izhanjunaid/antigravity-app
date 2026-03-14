import 'dart:typed_data';
import 'package:ibex_app/core/models/assignment_model.dart';
import 'package:ibex_app/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentService {
  final _client = SupabaseClientHelper.client;

  static const _select =
      '*, classes(subject_name), assignment_attachments(id, assignment_id, file_name, file_url, file_type, file_size, uploaded_at)';

  /// Fetches all assignments visible to the current user (RLS enforced).
  Future<List<AssignmentModel>> getMyAssignments() async {
    final response = await _client
        .from('assignments')
        .select(_select)
        .order('due_date', ascending: true);
    return response.map((e) => AssignmentModel.fromJson(e)).toList();
  }

  /// Fetches assignments for a specific class.
  Future<List<AssignmentModel>> getClassAssignments(String classId) async {
    final response = await _client
        .from('assignments')
        .select(_select)
        .eq('class_id', classId)
        .order('due_date', ascending: true);
    return response.map((e) => AssignmentModel.fromJson(e)).toList();
  }

  /// Fetches a single assignment by ID.
  Future<AssignmentModel?> getAssignmentById(String id) async {
    final response = await _client
        .from('assignments')
        .select(_select)
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return AssignmentModel.fromJson(response);
  }

  /// Creates a new assignment (teacher only).
  Future<AssignmentModel> createAssignment({
    required String classId,
    required String title,
    String? description,
    DateTime? dueDate,
    String? attachmentUrl,
    int? points,
    String? topic,
  }) async {
    final response = await _client
        .from('assignments')
        .insert({
          'class_id': classId,
          'title': title,
          'description': description,
          'due_date': dueDate?.toIso8601String(),
          'attachment_url': attachmentUrl,
          'points': points,
          'topic': topic,
        })
        .select(_select)
        .single();
    return AssignmentModel.fromJson(response);
  }

  /// Uploads a file to Supabase Storage and inserts an attachment row.
  Future<void> uploadAttachment({
    required String assignmentId,
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
    int? fileSize,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/$assignmentId/$fileName';

    // Upload file to storage
    await _client.storage.from('assignment-attachments').uploadBinary(
          path,
          fileBytes,
          fileOptions: mimeType != null
              ? FileOptions(contentType: mimeType)
              : const FileOptions(),
        );

    // Get the public/signed URL - using signed URL since bucket is private
    final signedUrl = await _client.storage
        .from('assignment-attachments')
        .createSignedUrl(path, 60 * 60 * 24 * 365); // 1 year

    // Insert attachment record
    await _client.from('assignment_attachments').insert({
      'assignment_id': assignmentId,
      'file_name': fileName,
      'file_url': signedUrl,
      'file_type': mimeType,
      'file_size': fileSize,
    });
  }

  /// Deletes an assignment by ID.
  Future<void> deleteAssignment(String id) async {
    await _client.from('assignments').delete().eq('id', id);
  }

  /// Fetches upcoming assignments (due in the future).
  Future<List<AssignmentModel>> getUpcomingAssignments() async {
    final response = await _client
        .from('assignments')
        .select(_select)
        .gte('due_date', DateTime.now().toIso8601String())
        .order('due_date', ascending: true)
        .limit(10);
    return response.map((e) => AssignmentModel.fromJson(e)).toList();
  }

  /// Alias for getAssignmentById.
  Future<AssignmentModel?> getById(String id) => getAssignmentById(id);
}
