import 'package:ibex_app/core/models/grade_model.dart';
import 'package:ibex_app/core/supabase/supabase_client.dart';

class GradeService {
  final _client = SupabaseClientHelper.client;

  /// Fetches all grades.
  Future<List<GradeModel>> getAllGrades() async {
    final response = await _client.from('grades').select().order('name');
    return response.map((e) => GradeModel.fromJson(e)).toList();
  }

  /// Creates a new grade (principal only).
  Future<GradeModel> createGrade(String name) async {
    final response = await _client
        .from('grades')
        .insert({'name': name})
        .select()
        .single();
    return GradeModel.fromJson(response);
  }

  /// Deletes a grade by ID.
  Future<void> deleteGrade(String id) async {
    await _client.from('grades').delete().eq('id', id);
  }
}
