import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';
import 'dart:developer' as developer;

class AlertService {
  static const String _alertsKey = 'user_alerts';

  Future<RateAlert> createAlert({
    required String rateType,
    required String conditionType,
    required double targetValue,
  }) async {
    final newAlert = RateAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rateType: rateType,
      conditionType: conditionType,
      targetValue: targetValue,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final alerts = await getUserAlerts();
    alerts.add(newAlert);
    await _saveAlerts(alerts);

    developer.log('Created alert locally: ${newAlert.rateDisplayName} ${newAlert.displayCondition} ${newAlert.targetValue}', 
                 name: 'AlertService');
    
    return newAlert;
  }

  Future<List<RateAlert>> getUserAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString(_alertsKey);
      
      if (alertsJson == null) return [];
      
      final List<dynamic> alertsList = json.decode(alertsJson);
      return alertsList.map((json) => RateAlert.fromJson(json)).toList();
    } catch (e) {
      developer.log('Error loading alerts: $e', name: 'AlertService');
      return [];
    }
  }

  Future<void> deleteAlert(String alertId) async {
    final alerts = await getUserAlerts();
    alerts.removeWhere((alert) => alert.id == alertId);
    await _saveAlerts(alerts);
    
    developer.log('Deleted alert: $alertId', name: 'AlertService');
  }

  Future<void> updateAlert(String alertId, {bool? isActive}) async {
    final alerts = await getUserAlerts();
    final alertIndex = alerts.indexWhere((alert) => alert.id == alertId);
    
    if (alertIndex != -1 && isActive != null) {
      alerts[alertIndex] = alerts[alertIndex].copyWith(isActive: isActive);
      await _saveAlerts(alerts);
      
      developer.log('Updated alert $alertId to ${isActive ? "active" : "inactive"}', 
                   name: 'AlertService');
    }
  }

  Future<void> _saveAlerts(List<RateAlert> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = json.encode(alerts.map((alert) => alert.toJson()).toList());
      await prefs.setString(_alertsKey, alertsJson);
    } catch (e) {
      developer.log('Error saving alerts: $e', name: 'AlertService');
      throw Exception('Failed to save alerts: $e');
    }
  }

  Future<void> clearAllAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alertsKey);
    developer.log('Cleared all alerts', name: 'AlertService');
  }
}