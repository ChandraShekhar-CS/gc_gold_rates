import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';
import 'dart:developer' as developer;

class AlertProvider with ChangeNotifier {
  final AlertService _alertService = AlertService();
  
  List<RateAlert> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RateAlert> get alerts => List.unmodifiable(_alerts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<RateAlert> get activeAlerts => 
      _alerts.where((alert) => alert.isActive).toList();

  Future<void> loadAlerts() async {
    _setLoading(true);
    _clearError();
    
    try {
      _alerts = await _alertService.getUserAlerts();
      developer.log('Loaded ${_alerts.length} alerts', name: 'AlertProvider');
    } catch (e) {
      _setError(e.toString());
      developer.log('Error loading alerts: $e', name: 'AlertProvider');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createAlert({
    required String rateType,
    required String conditionType,
    required double targetValue,
  }) async {
    _clearError();
    
    if (_hasConflictingAlert(rateType, conditionType, targetValue)) {
      _setError('Similar alert already exists for this rate and condition');
      return false;
    }

    try {
      final newAlert = await _alertService.createAlert(
        rateType: rateType,
        conditionType: conditionType,
        targetValue: targetValue,
      );
      
      _alerts.add(newAlert);
      notifyListeners();
      
      developer.log('Created alert: ${newAlert.rateDisplayName} ${newAlert.displayCondition} ${newAlert.targetValue}', 
                   name: 'AlertProvider');
      return true;
    } catch (e) {
      _setError(e.toString());
      developer.log('Error creating alert: $e', name: 'AlertProvider');
      return false;
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    _clearError();
    
    try {
      await _alertService.deleteAlert(alertId);
      _alerts.removeWhere((alert) => alert.id == alertId);
      notifyListeners();
      
      developer.log('Deleted alert: $alertId', name: 'AlertProvider');
      return true;
    } catch (e) {
      _setError(e.toString());
      developer.log('Error deleting alert: $e', name: 'AlertProvider');
      return false;
    }
  }

  Future<bool> toggleAlert(String alertId) async {
    _clearError();
    
    final alertIndex = _alerts.indexWhere((alert) => alert.id == alertId);
    if (alertIndex == -1) {
      _setError('Alert not found');
      return false;
    }

    final alert = _alerts[alertIndex];
    final newActiveState = !alert.isActive;

    try {
      await _alertService.updateAlert(alertId, isActive: newActiveState);
      _alerts[alertIndex] = alert.copyWith(isActive: newActiveState);
      notifyListeners();
      
      developer.log('Toggled alert $alertId to ${newActiveState ? "active" : "inactive"}', 
                   name: 'AlertProvider');
      return true;
    } catch (e) {
      _setError(e.toString());
      developer.log('Error toggling alert: $e', name: 'AlertProvider');
      return false;
    }
  }

  bool _hasConflictingAlert(String rateType, String conditionType, double targetValue) {
    return _alerts.any((alert) => 
        alert.rateType == rateType && 
        alert.conditionType == conditionType && 
        (alert.targetValue - targetValue).abs() < 0.01 &&
        alert.isActive);
  }

  int getAlertsCountForRate(String rateType) {
    return _alerts.where((alert) => 
        alert.rateType == rateType && alert.isActive).length;
  }

  List<RateAlert> getAlertsForRate(String rateType) {
    return _alerts.where((alert) => alert.rateType == rateType).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  Future<void> refreshAlerts() async {
    await loadAlerts();
  }
}