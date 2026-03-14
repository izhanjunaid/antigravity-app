import 'package:flutter/material.dart';
import 'package:ibex_app/core/supabase/supabase_client.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showToaster(String title, String message, {VoidCallback? onTap}) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: onTap != null
            ? SnackBarAction(label: 'VIEW', onPressed: onTap)
            : null,
      ),
    );
  }

  /// Registers the device's FCM/APNs token with the backend edge function.
  /// Note: Requires full Firebase setup (`flutterfire configure`) for production.
  static Future<void> registerPushToken() async {
    try {
      // 1. Request permission & get token (Mocked for now since Firebase isn't configured)
      // final messaging = FirebaseMessaging.instance;
      // await messaging.requestPermission();
      // final token = await messaging.getToken();
      final mockToken =
          'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';

      // 2. Send token to Supabase Edge Function
      final client = SupabaseClientHelper.client;
      await client.functions.invoke(
        'notifications',
        body: {
          'action': 'register_token',
          'token': mockToken,
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        },
      );
      debugPrint('Push token registered successfully via Edge Function.');
    } catch (e) {
      debugPrint('Failed to register push token: $e');
    }
  }
}
