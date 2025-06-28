class RateAlert {
  final String id;
  final String rateType;
  final String conditionType;
  final double targetValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? triggeredAt;

  RateAlert({
    required this.id,
    required this.rateType,
    required this.conditionType,
    required this.targetValue,
    required this.isActive,
    required this.createdAt,
    this.triggeredAt,
  });

  factory RateAlert.fromJson(Map<String, dynamic> json) {
    return RateAlert(
      id: json['id'].toString(),
      rateType: json['rate_type'] ?? '',
      conditionType: json['condition_type'] ?? '',
      targetValue: (json['target_value'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      triggeredAt: json['triggered_at'] != null 
          ? DateTime.parse(json['triggered_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rate_type': rateType,
      'condition_type': conditionType,
      'target_value': targetValue,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'triggered_at': triggeredAt?.toIso8601String(),
    };
  }

  RateAlert copyWith({
    String? id,
    String? rateType,
    String? conditionType,
    double? targetValue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? triggeredAt,
  }) {
    return RateAlert(
      id: id ?? this.id,
      rateType: rateType ?? this.rateType,
      conditionType: conditionType ?? this.conditionType,
      targetValue: targetValue ?? this.targetValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }

  String get displayCondition {
    return conditionType == 'above' ? 'Above' : 'Below';
  }

  String get rateDisplayName {
    switch (rateType) {
      case 'gold':
        return 'Gold 995';
      case 'goldfuture':
        return 'Gold Future';
      case 'silverfuture':
        return 'Silver Future';
      case 'dollarinr':
        return 'USD/INR';
      case 'golddollar':
        return 'Gold/USD';
      case 'silverdollar':
        return 'Silver/USD';
      case 'goldrefine':
        return 'Gold Refine';
      case 'goldrtgs':
        return 'Gold RTGS';
      default:
        return rateType.toUpperCase();
    }
  }

  bool checkCondition(double currentRate) {
    if (conditionType == 'above') {
      return currentRate > targetValue;
    } else {
      return currentRate < targetValue;
    }
  }
}