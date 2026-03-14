import 'package:ibex_app/core/supabase/supabase_client.dart';
import 'package:ibex_app/core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  final _client = SupabaseClientHelper.client;
  RealtimeChannel? _announcementsChannel;
  RealtimeChannel? _assignmentsChannel;

  void initialize() {
    _listenToAnnouncements();
    _listenToAssignments();
  }

  void _listenToAnnouncements() {
    _announcementsChannel = _client
        .channel('public:announcements')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            final newAnnouncement = payload.newRecord;
            final content = newAnnouncement['content'] as String?;
            if (content != null && content.isNotEmpty) {
              NotificationService.showToaster(
                'New Announcement',
                content.length > 50
                    ? '${content.substring(0, 50)}...'
                    : content,
              );
            }
          },
        )
        .subscribe();
  }

  void _listenToAssignments() {
    _assignmentsChannel = _client
        .channel('public:assignments')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'assignments',
          callback: (payload) {
            final newAssignment = payload.newRecord;
            final title = newAssignment['title'] as String?;
            if (title != null) {
              NotificationService.showToaster('New Assignment', title);
            }
          },
        )
        .subscribe();
  }

  void dispose() {
    if (_announcementsChannel != null) {
      _client.removeChannel(_announcementsChannel!);
    }
    if (_assignmentsChannel != null) {
      _client.removeChannel(_assignmentsChannel!);
    }
  }
}
