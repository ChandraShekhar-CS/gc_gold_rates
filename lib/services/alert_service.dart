import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/alert_model.dart';
import 'dart:developer' as developer;

class AlertService {
  static const String _baseUrl =
      "https://goldrate.divyanshbansal.com/api/alerts";
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<String?> _getFcmToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      developer.log('Error getting FCM token: $e', name: 'AlertService');
      return null;
    }
  }

  Future<RateAlert> createAlert({
    required String rateType,
    required String conditionType,
    required double targetValue,
  }) async {
    final fcmToken = await _getFcmToken();
    if (fcmToken == null) {
      throw Exception('Unable to get device token for notifications');
    }

    final alertData = {
      'fcm_token': fcmToken,
      'rate_type': rateType,
      'condition_type': conditionType,
      'target_value': targetValue,
      'is_active': true,
    };

    developer.log(
      'Creating alert: $rateType $conditionType $targetValue',
      name: 'AlertService',
    );
    developer.log('Sending to: $_baseUrl', name: 'AlertService');
    developer.log('Data: $alertData', name: 'AlertService');

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(alertData),
          )
          .timeout(const Duration(seconds: 15));

      developer.log(
        'Response status: ${response.statusCode}',
        name: 'AlertService',
      );
      developer.log('Response body: ${response.body}', name: 'AlertService');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final alert = RateAlert.fromJson(responseData['alert']);

        developer.log(
          'Created alert successfully: ${alert.rateDisplayName} ${alert.displayCondition} ${alert.targetValue}',
          name: 'AlertService',
        );

        return alert;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ??
              'Failed to create alert: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      developer.log('Error creating alert: $e', name: 'AlertService');
      throw Exception('Failed to create alert: $e');
    }
  }

  Future<List<RateAlert>> getUserAlerts() async {
    final fcmToken = await _getFcmToken();
    if (fcmToken == null) {
      throw Exception('Unable to get device token');
    }

    developer.log(
      'Fetching alerts for token: ${fcmToken.substring(0, 20)}...',
      name: 'AlertService',
    );

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$fcmToken'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      developer.log(
        'Fetch response status: ${response.statusCode}',
        name: 'AlertService',
      );
      developer.log(
        'Fetch response body: ${response.body}',
        name: 'AlertService',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final alertsJson = responseData['alerts'] as List;
        final alerts = alertsJson
            .map((json) => RateAlert.fromJson(json))
            .toList();

        developer.log(
          'Loaded ${alerts.length} alerts from server',
          name: 'AlertService',
        );
        return alerts;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ??
              'Failed to fetch alerts: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      developer.log('Error fetching alerts: $e', name: 'AlertService');
      throw Exception('Failed to fetch alerts: $e');
    }
  }

  Future<void> deleteAlert(String alertId) async {
    developer.log('Deleting alert: $alertId', name: 'AlertService');

    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/$alertId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      developer.log(
        'Delete response status: ${response.statusCode}',
        name: 'AlertService',
      );

      if (response.statusCode == 200) {
        developer.log(
          'Deleted alert successfully: $alertId',
          name: 'AlertService',
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ??
              'Failed to delete alert: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      developer.log('Error deleting alert: $e', name: 'AlertService');
      throw Exception('Failed to delete alert: $e');
    }
  }

  Future<void> updateAlert(String alertId, {bool? isActive}) async {
    if (isActive == null) return;

    final updateData = {'is_active': isActive};

    developer.log(
      'Updating alert $alertId to ${isActive ? "active" : "inactive"}',
      name: 'AlertService',
    );

    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/$alertId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(updateData),
          )
          .timeout(const Duration(seconds: 15));

      developer.log(
        'Update response status: ${response.statusCode}',
        name: 'AlertService',
      );

      if (response.statusCode == 200) {
        developer.log(
          'Updated alert successfully: $alertId',
          name: 'AlertService',
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ??
              'Failed to update alert: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      developer.log('Error updating alert: $e', name: 'AlertService');
      throw Exception('Failed to update alert: $e');
    }
  }

  Future<void> clearAllAlerts() async {
    final fcmToken = await _getFcmToken();
    if (fcmToken == null) {
      throw Exception('Unable to get device token');
    }

    developer.log('Clearing all alerts for device', name: 'AlertService');

    try {
      final alerts = await getUserAlerts();

      for (final alert in alerts) {
        await deleteAlert(alert.id);
      }

      developer.log('Cleared all alerts successfully', name: 'AlertService');
    } catch (e) {
      developer.log('Error clearing alerts: $e', name: 'AlertService');
      throw Exception('Failed to clear alerts: $e');
    }
  }

  Future<void> refreshFcmToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      final newToken = await _firebaseMessaging.getToken();
      developer.log(
        'FCM token refreshed: ${newToken?.substring(0, 20)}...',
        name: 'AlertService',
      );
    } catch (e) {
      developer.log('Error refreshing FCM token: $e', name: 'AlertService');
    }
  }

  Future<bool> testConnection() async {
    try {
      final healthUrl = _baseUrl.replaceAll('/alerts', '/health');
      final response = await http
          .get(Uri.parse(healthUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      developer.log(
        'Backend health check: ${response.statusCode}',
        name: 'AlertService',
      );
      developer.log('Backend response: ${response.body}', name: 'AlertService');

      return response.statusCode == 200;
    } catch (e) {
      developer.log('Backend connection test failed: $e', name: 'AlertService');
      return false;
    }
  }
}
