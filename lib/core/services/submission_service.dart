import 'dart:typed_data';
import 'package:ibex_app/core/models/submission_model.dart';
import 'package:ibex_app/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionService {
  final _client = SupabaseClientHelper.client;

  /// Submits an assignment (student only).
  Future<SubmissionModel> submitAssignment({
    required String assignmentId,
    String? submissionUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('submissions')
        .upsert(
          {
            'assignment_id': assignmentId,
            'student_id': userId,
            'submission_url': submissionUrl,
          },
          onConflict: 'assignment_id, student_id',
        )
        .select()
        .single();
    return SubmissionModel.fromJson(response);
  }

  /// Gets the current student's submission for an assignment.
  Future<SubmissionModel?> getMySubmission(String assignmentId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final response = await _client
        .from('submissions')
        .select('*, assignments(title), submission_attachments(*)')
        .eq('assignment_id', assignmentId)
        .eq('student_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return SubmissionModel.fromJson(response);
  }

  /// Gets all submissions for an assignment (teacher view).
  Future<List<SubmissionModel>> getAssignmentSubmissions(
    String assignmentId,
  ) async {
    final response = await _client
        .from('submissions')
        .select('*, users(name), assignments(title), submission_attachments(*)')
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false);
    return response.map((e) => SubmissionModel.fromJson(e)).toList();
  }

  /// Grades a submission (teacher only).
  Future<void> gradeSubmission({
    required String submissionId,
    required String grade,
    String? feedback,
  }) async {
    await _client
        .from('submissions')
        .update({'grade': grade, 'feedback': feedback})
        .eq('id', submissionId);
  }

  /// Gets the count of ungraded submissions for the teacher's classes.
  Future<int> getUngradedCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('submissions')
        .select('id, assignments!inner(class_id, classes!inner(teacher_id))')
        .isFilter('grade', null);

    // Filter by teacher's classes client-side since the query is complex
    int count = 0;
    for (final sub in response) {
      final assignments = sub['assignments'] as Map<String, dynamic>?;
      if (assignments != null) {
        final classes = assignments['classes'] as Map<String, dynamic>?;
        if (classes != null && classes['teacher_id'] == userId) {
          count++;
        }
      }
    }
    return count;
  }

  /// Alias for submitAssignment — used by the submission screen.
  Future<SubmissionModel> submitWork({
    required String assignmentId,
    String? submissionUrl,
  }) {
    return submitAssignment(
      assignmentId: assignmentId,
      submissionUrl: submissionUrl,
    );
  }

  /// Fetches a single submission by ID.
  Future<SubmissionModel?> getById(String id) async {
    final response = await _client
        .from('submissions')
        .select('*, users(name), assignments(title), submission_attachments(*)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return SubmissionModel.fromJson(response);
  }

  /// Uploads a file to Supabase Storage and inserts an attachment row.
  Future<void> uploadAttachment({
    required String submissionId,
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
    int? fileSize,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/$submissionId/$fileName';

    // Upload file to storage
    await _client.storage.from('submission-attachments').uploadBinary(
          path,
          fileBytes,
          fileOptions: mimeType != null
              ? FileOptions(contentType: mimeType)
              : const FileOptions(),
        );

    // Get the signed URL
    final signedUrl = await _client.storage
        .from('submission-attachments')
        .createSignedUrl(path, 60 * 60 * 24 * 365); // 1 year

    // Insert attachment record
    await _client.from('submission_attachments').insert({
      'submission_id': submissionId,
      'file_name': fileName,
      'file_url': signedUrl,
      'file_type': mimeType,
      'file_size': fileSize,
    });
  }
}
