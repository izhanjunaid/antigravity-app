import 'package:ibex_app/core/models/announcement_model.dart';
import 'package:ibex_app/core/supabase/supabase_client.dart';

class AnnouncementService {
  final _client = SupabaseClientHelper.client;

  /// Fetches all announcements visible to the current user (RLS enforced).
  Future<List<AnnouncementModel>> getMyAnnouncements() async {
    final response = await _client
        .from('announcements')
        .select('*, users(name, role, profile_pic), classes(subject_name)')
        .order('created_at', ascending: false)
        .limit(50);
    return response.map((e) => AnnouncementModel.fromJson(e)).toList();
  }

  /// Fetches announcements for a specific class.
  Future<List<AnnouncementModel>> getClassAnnouncements(String classId) async {
    final response = await _client
        .from('announcements')
        .select('*, users(name, role, profile_pic)')
        .eq('class_id', classId)
        .order('created_at', ascending: false);
    return response.map((e) => AnnouncementModel.fromJson(e)).toList();
  }

  /// Fetches section-wide announcements.
  Future<List<AnnouncementModel>> getSectionAnnouncements(
    String sectionId,
  ) async {
    final response = await _client
        .from('announcements')
        .select('*, users(name, role, profile_pic)')
        .eq('section_id', sectionId)
        .isFilter('class_id', null)
        .order('created_at', ascending: false);
    return response.map((e) => AnnouncementModel.fromJson(e)).toList();
  }

  /// Fetches global announcements (no class or section).
  Future<List<AnnouncementModel>> getGlobalAnnouncements() async {
    final response = await _client
        .from('announcements')
        .select('*, users(name, role, profile_pic)')
        .isFilter('class_id', null)
        .isFilter('section_id', null)
        .order('created_at', ascending: false);
    return response.map((e) => AnnouncementModel.fromJson(e)).toList();
  }

  /// Creates a new announcement.
  Future<AnnouncementModel> createAnnouncement({
    String? classId,
    String? sectionId,
    required String content,
    String? attachmentUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('announcements')
        .insert({
          'class_id': classId,
          'section_id': sectionId,
          'poster_id': userId,
          'content': content,
          'attachment_url': attachmentUrl,
        })
        .select('*, users(name, role, profile_pic)')
        .single();
    return AnnouncementModel.fromJson(response);
  }

  /// Deletes an announcement.
  Future<void> deleteAnnouncement(String id) async {
    await _client.from('announcements').delete().eq('id', id);
  }
}
