import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import '../../main.dart';

class NotificationService {
  static Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.high,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // طلب صلاحية الإشعارات (Android 13+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// إرسال إشعار نقص المخزون
  static Future<void> showLowStockNotification({
    required String productName,
    required int quantity,
    required int threshold,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1565C0),
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      AppConstants.lowStockNotificationId + productName.hashCode.abs() % 1000,
      '⚠️ تنبيه نقص المخزون',
      'المنتج "$productName" وصل إلى $quantity وحدة (الحد الأدنى: $threshold)',
      details,
    );
  }

  /// إلغاء جميع الإشعارات
  static Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

class Color {
  final int value;
  const Color(this.value);
}
