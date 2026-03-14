import 'package:ibex_app/core/models/section_model.dart';
import 'package:ibex_app/core/supabase/supabase_client.dart';

class SectionService {
  final _client = SupabaseClientHelper.client;

  /// Fetches all sections with grade and head teacher info.
  Future<List<SectionModel>> getAllSections() async {
    final response = await _client
        .from('sections')
        .select(
          '*, grades(name), head_teacher:users!sections_head_teacher_id_fkey(name)',
        )
        .order('created_at');
    return response.map((e) => SectionModel.fromJson(e)).toList();
  }

  /// Fetches sections by grade ID.
  Future<List<SectionModel>> getSectionsByGrade(String gradeId) async {
    final response = await _client
        .from('sections')
        .select(
          '*, grades(name), head_teacher:users!sections_head_teacher_id_fkey(name)',
        )
        .eq('grade_id', gradeId)
        .order('name');
    return response.map((e) => SectionModel.fromJson(e)).toList();
  }

  /// Fetches sections headed by the current user (section_head role).
  Future<List<SectionModel>> getMySections() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _client
        .from('sections')
        .select('*, grades(name)')
        .eq('head_teacher_id', userId)
        .order('name');
    return response.map((e) => SectionModel.fromJson(e)).toList();
  }

  /// Creates a new section (principal only).
  Future<SectionModel> createSection({
    required String gradeId,
    required String name,
    String? headTeacherId,
  }) async {
    final response = await _client
        .from('sections')
        .insert({
          'grade_id': gradeId,
          'name': name,
          'head_teacher_id': headTeacherId,
        })
        .select('*, grades(name)')
        .single();
    return SectionModel.fromJson(response);
  }

  /// Deletes a section by ID.
  Future<void> deleteSection(String id) async {
    await _client.from('sections').delete().eq('id', id);
  }
}
