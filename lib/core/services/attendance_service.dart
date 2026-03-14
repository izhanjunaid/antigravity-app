import 'package:ibex_app/core/models/attendance_model.dart';
import 'package:ibex_app/core/supabase/supabase_client.dart';

class AttendanceService {
  final _client = SupabaseClientHelper.client;

  /// Marks attendance for a student in a class.
  Future<AttendanceModel> markAttendance({
    required String classId,
    required String studentId,
    required DateTime date,
    required String status,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    // Upsert: update if exists, insert if not
    final response = await _client
        .from('attendance')
        .upsert({
          'class_id': classId,
          'student_id': studentId,
          'date': dateStr,
          'status': status,
        })
        .select()
        .single();
    return AttendanceModel.fromJson(response);
  }

  /// Marks attendance for multiple students at once.
  Future<void> markBulkAttendance({
    required String classId,
    required DateTime date,
    required Map<String, String> studentStatuses, // studentId -> status
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final records = studentStatuses.entries
        .map(
          (e) => {
            'class_id': classId,
            'student_id': e.key,
            'date': dateStr,
            'status': e.value,
          },
        )
        .toList();

    await _client.from('attendance').upsert(records);
  }

  /// Gets attendance records for a class on a specific date.
  Future<List<AttendanceModel>> getClassAttendance({
    required String classId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _client
        .from('attendance')
        .select('*, users(name, profile_pic)')
        .eq('class_id', classId)
        .eq('date', dateStr)
        .order('users(name)');
    return response.map((e) => AttendanceModel.fromJson(e)).toList();
  }

  /// Gets the current student's attendance history.
  Future<List<AttendanceModel>> getMyAttendance() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _client
        .from('attendance')
        .select('*')
        .eq('student_id', userId)
        .order('date', ascending: false)
        .limit(100);
    return response.map((e) => AttendanceModel.fromJson(e)).toList();
  }

  /// Gets attendance percentage for a student.
  Future<double> getAttendancePercentage(String studentId) async {
    final response = await _client
        .from('attendance')
        .select('status')
        .eq('student_id', studentId);
    if (response.isEmpty) return 100.0;
    final present = response.where((e) => e['status'] == 'present').length;
    return (present / response.length) * 100;
  }
}
