import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  String? _currentFcmToken;

  String? get currentFcmToken => _currentFcmToken;

  Future<void> initNotifications() async {
    await _requestPermissions();
    await _getFcmToken();
    _setupMessageHandling();
  }

  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      developer.log('User denied notification permissions', name: 'NotificationService');
    } else {
      developer.log('Notification permissions granted', name: 'NotificationService');
    }
  }

  Future<void> _getFcmToken() async {
    try {
      _currentFcmToken = await _firebaseMessaging.getToken();
      developer.log('FCM Token: $_currentFcmToken', name: 'NotificationService');

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _currentFcmToken = newToken;
        developer.log('FCM Token refreshed: $newToken', name: 'NotificationService');
      });
    } catch (e) {
      developer.log('Error getting FCM token: $e', name: 'NotificationService');
    }
  }

  void _setupMessageHandling() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Received foreground message: ${message.messageId}', name: 'NotificationService');
      
      if (message.notification != null) {
        developer.log(
          'Notification: ${message.notification!.title} - ${message.notification!.body}',
          name: 'NotificationService'
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('Notification tapped - opened app: ${message.messageId}', name: 'NotificationService');
      _handleNotificationTap(message);
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('App launched from notification: ${message.messageId}', name: 'NotificationService');
        _handleNotificationTap(message);
      }
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    
    if (data.containsKey('alert_type') && data['alert_type'] == 'rate_alert') {
      final rateType = data['rate_type'];
      final targetValue = data['target_value'];
      final conditionType = data['condition_type'];
      
      developer.log(
        'Rate alert notification tapped - Rate: $rateType, Target: $targetValue, Condition: $conditionType',
        name: 'NotificationService'
      );
    }
  }

  Future<String?> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _currentFcmToken = await _firebaseMessaging.getToken();
      developer.log('FCM token refreshed: $_currentFcmToken', name: 'NotificationService');
      return _currentFcmToken;
    } catch (e) {
      developer.log('Error refreshing FCM token: $e', name: 'NotificationService');
      return null;
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('Background message received: ${message.messageId}', name: 'BackgroundHandler');
}