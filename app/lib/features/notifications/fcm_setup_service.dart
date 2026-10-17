import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/services/api_client.dart';

class FcmSetupService {
  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Token can rotate (app reinstall, restore, etc.) — keep the backend in sync.
    messaging.onTokenRefresh.listen(_registerToken);
  }

  static Future<void> _registerToken(String token) async {
    try {
      await ApiClient.instance.client.patch('/users/me/fcm-token', data: {'fcmToken': token});
    } catch (_) {
      // Non-fatal — worst case the user misses a push until the next successful sync.
      // A retry queue would be the production follow-up here.
    }
  }
}
