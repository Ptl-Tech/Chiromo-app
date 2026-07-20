import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint("Handling a background message: ${message.messageId}");
}

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }

    // 2. Initialize local notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);
    await _localNotifications.initialize(settings: initSettings);

    // 3. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      
      if (message.notification != null) {
        _showLocalNotification(message.notification!);
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${message.notification!.title}: ${message.notification!.body}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Handle notification click if needed
              },
            ),
          ),
        );
      }
    });
  }

  Future<void> _showLocalNotification(RemoteNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'chiromo_high_importance_channel', // id
      'High Importance Notifications', // title
      channelDescription: 'This channel is used for important clinical notifications.',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
