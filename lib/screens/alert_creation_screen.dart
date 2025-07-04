import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../providers/rates_provider.dart';

class AlertCreationScreen extends StatefulWidget {
  final String? initialRateType;
  
  const AlertCreationScreen({super.key, this.initialRateType});

  @override
  State<AlertCreationScreen> createState() => _AlertCreationScreenState();
}

class _AlertCreationScreenState extends State<AlertCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetValueController = TextEditingController();
  
  String _selectedRateType = 'gold';
  String _selectedCondition = 'above';
  bool _isCreating = false;

  final List<Map<String, String>> _rateOptions = [
    {'value': 'gold', 'label': 'Gold 995'},
    {'value': 'goldfuture', 'label': 'Gold Future'},
    {'value': 'silverfuture', 'label': 'Silver Future'},
    {'value': 'dollarinr', 'label': 'USD/INR'},
    {'value': 'golddollar', 'label': 'Gold/USD'},
    {'value': 'silverdollar', 'label': 'Silver/USD'},
    {'value': 'goldrefine', 'label': 'Gold Refine'},
    {'value': 'goldrtgs', 'label': 'Gold RTGS'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialRateType != null &&
        _rateOptions.any((option) => option['value'] == widget.initialRateType)) {
      _selectedRateType = widget.initialRateType!;
    }
  }

  @override
  void dispose() {
    _targetValueController.dispose();
    super.dispose();
  }

  double? _getCurrentRate() {
    final ratesProvider = context.read<RatesProvider>();
    final rateCard = ratesProvider.rateCards
        .where((card) => card.apiSymbol == _selectedRateType)
        .firstOrNull;
    
    if (rateCard != null) {
      return double.tryParse(rateCard.buyRate);
    }
    return null;
  }

  Future<void> _createAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final targetValue = double.parse(_targetValueController.text);
    final alertProvider = context.read<AlertProvider>();

    final success = await alertProvider.createAlert(
      rateType: _selectedRateType,
      conditionType: _selectedCondition,
      targetValue: targetValue,
    );

    setState(() => _isCreating = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alertProvider.errorMessage ?? 'Failed to create alert'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _fillCurrentRate() {
    final currentRate = _getCurrentRate();
    if (currentRate != null) {
      _targetValueController.text = currentRate.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRate = _getCurrentRate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Price Alert'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alert Configuration',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedRateType,
                      decoration: InputDecoration(
                        labelText: 'Select Rate Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.trending_up),
                      ),
                      items: _rateOptions.map((option) {
                        return DropdownMenuItem(
                          value: option['value'],
                          child: Text(option['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRateType = value);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a rate type';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.compare_arrows),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'above',
                          child: Row(
                            children: [
                              Icon(Icons.keyboard_arrow_up, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Above'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'below',
                          child: Row(
                            children: [
                              Icon(Icons.keyboard_arrow_down, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Below'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCondition = value);
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _targetValueController,
                      decoration: InputDecoration(
                        labelText: 'Target Price (₹)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.currency_rupee),
                        suffixIcon: currentRate != null
                            ? IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _fillCurrentRate,
                                tooltip: 'Use current rate',
                              )
                            : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a target price';
                        }
                        final double? price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    
                    if (currentRate != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current rate: ₹${currentRate.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isCreating ? null : _createAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Alert',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How Alerts Work',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Alerts are monitored 24/7 on our servers\n'
                      '• You\'ll receive push notifications when conditions are met\n'
                      '• Alerts work even when the app is closed\n'
                      '• No impact on your device\'s battery life\n'
                      '• You can manage alerts anytime from the Alerts tab',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}