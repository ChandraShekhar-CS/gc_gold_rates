import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;

class NotificationService {
  // Get an instance of FirebaseMessaging
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Function to initialize notifications
  Future<void> initNotifications() async {
    // Request permission from the user (required for iOS and newer Android)
    await _firebaseMessaging.requestPermission();

    // Fetch the FCM token for this device
    final fcmToken = await _firebaseMessaging.getToken();

    // Print the token to the console (for now)
    // You will eventually send this token to your server
    developer.log('FCM Token: $fcmToken', name: 'NotificationService');

    // TODO: Send this token to your backend server and store it with a user ID
  }
}
