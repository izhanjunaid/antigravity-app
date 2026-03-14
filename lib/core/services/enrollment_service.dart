import 'package:ibex_app/core/models/enrollment_model.dart';
import 'package:ibex_app/core/supabase/supabase_client.dart';

class EnrollmentService {
  final _client = SupabaseClientHelper.client;

  /// Enrolls the current student in a class.
  Future<EnrollmentModel> enrollInClass(String classId) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('enrollments')
        .insert({
          'user_id': userId,
          'class_id': classId,
          'role_in_class': 'student',
        })
        .select()
        .single();
    return EnrollmentModel.fromJson(response);
  }

  /// Gets all enrollments for the current user.
  Future<List<EnrollmentModel>> getMyEnrollments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _client
        .from('enrollments')
        .select('*, classes(subject_name)')
        .eq('user_id', userId)
        .order('joined_at', ascending: false);
    return response.map((e) => EnrollmentModel.fromJson(e)).toList();
  }

  /// Gets all students enrolled in a class.
  Future<List<EnrollmentModel>> getClassEnrollments(String classId) async {
    final response = await _client
        .from('enrollments')
        .select('*, users(name)')
        .eq('class_id', classId)
        .eq('role_in_class', 'student')
        .order('joined_at');
    return response.map((e) => EnrollmentModel.fromJson(e)).toList();
  }

  /// Gets the count of students in a class.
  Future<int> getStudentCount(String classId) async {
    final response = await _client
        .from('enrollments')
        .select('id')
        .eq('class_id', classId)
        .eq('role_in_class', 'student');
    return response.length;
  }

  /// Checks if the current user is enrolled in a class.
  Future<bool> isEnrolled(String classId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final response = await _client
        .from('enrollments')
        .select('id')
        .eq('user_id', userId)
        .eq('class_id', classId)
        .maybeSingle();
    return response != null;
  }
}
