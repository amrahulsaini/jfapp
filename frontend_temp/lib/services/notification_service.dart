import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    // Request notification permission for Android 13+ (Tiramisu)
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    
    // Save FCM token to backend
    await _saveFCMTokenToBackend();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'jf_app_notifications', // id
        'JF App Notifications', // name
        description: 'Notifications for plan purchases and expirations',
        importance: Importance.high,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    print('Notification tapped: ${notificationResponse.payload}');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      await showNotification(
        title: message.notification!.title ?? 'JF Foundation',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'jf_app_notifications',
      'JF App Notifications',
      channelDescription: 'Notifications for plan purchases and expirations',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Show plan purchase success notification
  Future<void> showPlanPurchaseNotification({
    required String planName,
    required int viewsRemaining,
  }) async {
    print('showPlanPurchaseNotification called: $planName, $viewsRemaining views');
    try {
      await showNotification(
        title: '🎉 Plan Purchased Successfully!',
        body: 'You have purchased $planName. $viewsRemaining results available.',
        payload: 'plan_purchase',
      );
      print('Notification successfully triggered');
    } catch (e) {
      print('Notification error: $e');
    }
  }

  // Show plan expiring soon notification
  Future<void> showPlanExpiringNotification({
    required String planName,
    required int daysLeft,
    required int viewsRemaining,
  }) async {
    await showNotification(
      title: '⚠️ Plan Expiring Soon',
      body: 'Your $planName will expire in $daysLeft days. $viewsRemaining views remaining.',
      payload: 'plan_expiring',
    );
  }

  // Show plan expired notification
  Future<void> showPlanExpiredNotification({
    required String planName,
  }) async {
    await showNotification(
      title: '❌ Plan Expired',
      body: 'Your $planName has expired. Purchase a new plan to continue viewing results.',
      payload: 'plan_expired',
    );
  }

  // Show low views notification
  Future<void> showLowViewsNotification({
    required String planName,
    required int viewsRemaining,
  }) async {
    await showNotification(
      title: '⚡ Running Low on Views',
      body: 'Only $viewsRemaining views left in your $planName. Consider upgrading!',
      payload: 'low_views',
    );
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
  
  Future<void> _saveFCMTokenToBackend() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token == null) return;
      
      print('FCM Token: $token');
      
      final StorageService storageService = StorageService();
      final sessionToken = await storageService.getToken();
      
      if (sessionToken == null) {
        print('No session token, skipping FCM token save');
        return;
      }
      
      final response = await http.post(
        Uri.parse('https://jecrcfoundation.live/api/notifications/save-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
        body: json.encode({
          'fcm_token': token,
          'device_type': Platform.isIOS ? 'ios' : 'android',
        }),
      );
      
      if (response.statusCode == 200) {
        print('FCM token saved to backend successfully');
      } else {
        print('Failed to save FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}
