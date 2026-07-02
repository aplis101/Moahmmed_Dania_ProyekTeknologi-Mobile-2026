import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// خدمة الإشعارات المحلية - تُذكّر المستخدم قبل انتهاء صلاحية المواد الغذائية
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// تهيئة خدمة الإشعارات عند بدء التطبيق
  Future<void> initialize() async {
    try {
      // Note: tz.initializeTimeZones() is called in main() before this
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(initSettings);
    } catch (e) {
      debugPrint('NotificationService: Failed to initialize. This is expected on unsupported platforms (like Windows/Web): $e');
    }
  }

  /// جدولة إشعار لمادة غذائية على وشك الانتهاء
  /// [id] معرّف فريد للإشعار
  /// [itemName] اسم المادة الغذائية
  /// [daysBeforeExpiry] عدد الأيام قبل الانتهاء لإرسال التذكير
  /// [expiryDate] تاريخ الانتهاء الفعلي
  Future<void> scheduleExpiryNotification({
    required int id,
    required String itemName,
    required DateTime expiryDate,
    int daysBeforeExpiry = 2,
  }) async {
    try {
      final notifyDate = expiryDate.subtract(Duration(days: daysBeforeExpiry));

      // إذا كان التاريخ في الماضي، لا تجدول
      if (notifyDate.isBefore(DateTime.now())) return;

      final scheduledDate = tz.TZDateTime.from(notifyDate, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'expiry_channel',
        'Pengingat Kedaluwarsa',
        channelDescription: 'Notifikasi pengingat bahan makanan akan kedaluwarsa',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notifDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id,
        '⚠️ $itemName akan kedaluwarsa!',
        '$itemName akan kedaluwarsa dalam $daysBeforeExpiry hari. Segera masak untuk kurangi food waste! 🌿',
        scheduledDate,
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule expiry notification for $itemName: $e');
    }
  }

  /// إلغاء إشعار محدد
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('NotificationService: Failed to cancel notification with id $id: $e');
    }
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService: Failed to cancel all notifications: $e');
    }
  }

  /// إرسال إشعار فوري (للاختبار)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'expiry_channel',
        'Pengingat Kedaluwarsa',
        channelDescription: 'Notifikasi pengingat bahan makanan akan kedaluwarsa',
        importance: Importance.high,
        priority: Priority.high,
      );

      const notifDetails = NotificationDetails(android: androidDetails);

      await _plugin.show(0, title, body, notifDetails);
    } catch (e) {
      debugPrint('NotificationService: Failed to show immediate notification: $e');
    }
  }
}
