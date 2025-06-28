import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/alert_provider.dart';
import '../models/alert_model.dart';
import 'alert_creation_screen.dart';

class AlertManagementScreen extends StatefulWidget {
  const AlertManagementScreen({super.key});

  @override
  State<AlertManagementScreen> createState() => _AlertManagementScreenState();
}

class _AlertManagementScreenState extends State<AlertManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertProvider>().loadAlerts();
    });
  }

  Future<void> _refreshAlerts() async {
    await context.read<AlertProvider>().refreshAlerts();
  }

  void _showDeleteConfirmation(RateAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: Text(
          'Are you sure you want to delete the alert for ${alert.rateDisplayName} ${alert.displayCondition.toLowerCase()} ₹${alert.targetValue.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context.read<AlertProvider>().deleteAlert(alert.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alert deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshAlerts,
        child: Consumer<AlertProvider>(
          builder: (context, alertProvider, child) {
            if (alertProvider.isLoading && alertProvider.alerts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (alertProvider.errorMessage != null) {
              return _buildErrorView(alertProvider.errorMessage!);
            }

            if (alertProvider.alerts.isEmpty) {
              return _buildEmptyView();
            }

            return _buildAlertsList(alertProvider.alerts);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AlertCreationScreen(),
            ),
          );
        },
        backgroundColor: Colors.amber.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Alerts',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshAlerts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Price Alerts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first alert to get notified when prices reach your target levels.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AlertCreationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(List<RateAlert> alerts) {
    final activeAlerts = alerts.where((alert) => alert.isActive).toList();
    final inactiveAlerts = alerts.where((alert) => !alert.isActive).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (activeAlerts.isNotEmpty) ...[
          _buildSectionHeader('Active Alerts', activeAlerts.length),
          const SizedBox(height: 8),
          ...activeAlerts.map((alert) => _buildAlertCard(alert)),
          const SizedBox(height: 24),
        ],
        
        if (inactiveAlerts.isNotEmpty) ...[
          _buildSectionHeader('Inactive Alerts', inactiveAlerts.length),
          const SizedBox(height: 8),
          ...inactiveAlerts.map((alert) => _buildAlertCard(alert)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(RateAlert alert) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );

    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alert.isActive ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.isActive 
              ? Colors.amber.shade200 
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.rateDisplayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            alert.conditionType == 'above' 
                                ? Icons.keyboard_arrow_up 
                                : Icons.keyboard_arrow_down,
                            color: alert.conditionType == 'above' 
                                ? Colors.green 
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${alert.displayCondition} ${currencyFormatter.format(alert.targetValue)}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: alert.conditionType == 'above' 
                                  ? Colors.green.shade700 
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Switch(
                  value: alert.isActive,
                  onChanged: (value) async {
                    final success = await context.read<AlertProvider>().toggleAlert(alert.id);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.read<AlertProvider>().errorMessage ?? 'Failed to update alert',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  activeColor: Colors.amber.shade700,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created: ${dateFormatter.format(alert.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (alert.triggeredAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Triggered: ${dateFormatter.format(alert.triggeredAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                IconButton(
                  onPressed: () => _showDeleteConfirmation(alert),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade600,
                  tooltip: 'Delete Alert',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}