import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

class FcmService {
  static bool _initialized = false;
  static String? _token;

  static Future<void> initialize() async {
    if (!_initialized) {
      if (kIsWeb) {
        // On web, skip Firebase initialization unless options are configured via flutterfire.
        // This avoids: FirebaseOptions cannot be null when creating the default app.
        _initialized = true;
        return;
      }
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      _initialized = true;
    }

    if (kIsWeb) return; // skip web runtime permissions and listeners
    final messaging = FirebaseMessaging.instance;
    // iOS/Android 13+ require runtime permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Ensure notifications shown in foreground
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages and show as local notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Order Update';
      final body = message.notification?.body ?? '';
      final orderId = message.data['orderId'] ?? message.data['orderCode'] ?? '0';
      NotificationService.showOrderUpdateNotification(
        title: title,
        body: body,
        orderId: orderId,
      );
    });

    try {
      _token = await messaging.getToken();
    } catch (e) {
      print('FCM Token error: $e');
      // Continue without FCM token - app will still work
    }
  }

  static Future<String?> getToken() async {
    if (!_initialized) {
      await initialize();
    }
    if (kIsWeb) return null;
    try {
      _token ??= await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print('FCM getToken error: $e');
      return null;
    }
    return _token;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return; // not supported on web
  await Firebase.initializeApp();
  final title = message.notification?.title ?? 'Order Update';
  final body = message.notification?.body ?? '';
  final orderId = message.data['orderId'] ?? message.data['orderCode'] ?? '0';
  await NotificationService.showOrderUpdateNotification(
    title: title,
    body: body,
    orderId: orderId,
  );
}


