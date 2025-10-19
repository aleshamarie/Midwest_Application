import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/src/platform_specifics/android/notification_channel.dart' show AndroidNotificationChannel; // ensure channel type

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request notification permission
    await Permission.notification.request();

    // Initialize the plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_midwest');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Ensure Android channels exist before any FCM background notifications use them
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'order_updates_v2',
        'Order Updates',
        description: 'Notifications for order status updates',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'low_stock_v2',
        'Low Stock Alerts',
        description: 'Notifications for low stock items',
        importance: Importance.defaultImportance,
      ),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  static Future<void> showOrderUpdateNotification({
    required String title,
    required String body,
    required String orderId,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'order_updates_v2',
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_midwest',
      largeIcon: DrawableResourceAndroidBitmap('ic_midwest_color'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      orderId.hashCode,
      title,
      body,
      details,
      payload: orderId,
    );
  }

  static Future<void> showOrderPlacedNotification({
    required String orderId,
    required String total,
  }) async {
    await showOrderUpdateNotification(
      title: 'Order Placed Successfully!',
      body: 'Your order #$orderId (₱$total) has been placed and is being processed.',
      orderId: orderId,
    );
  }

  static Future<void> showOrderStatusUpdateNotification({
    required String orderId,
    required String status,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'Processing':
        title = 'Order Being Processed';
        body = 'Your order #$orderId is now being prepared.';
        break;
      case 'Delivered':
        title = 'Order Delivered!';
        body = 'Your order #$orderId has been delivered successfully.';
        break;
      case 'Cancelled':
        title = 'Order Cancelled';
        body = 'Your order #$orderId has been cancelled.';
        break;
      default:
        title = 'Order Update';
        body = 'Your order #$orderId status has been updated to $status.';
    }

    await showOrderUpdateNotification(
      title: title,
      body: body,
      orderId: orderId,
    );
  }

  static Future<void> showLowStockNotification({
    required String productName,
    required int stock,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'low_stock_v2',
      'Low Stock Alerts',
      channelDescription: 'Notifications for low stock items',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      productName.hashCode,
      'Low Stock Alert',
      '$productName is running low (${stock} left)',
      details,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
