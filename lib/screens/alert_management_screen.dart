import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/alert_provider.dart';
import '../models/alert_model.dart';
import 'alert_creation_screen.dart';

class AlertManagementScreen extends StatefulWidget {
  const AlertManagementScreen({Key? key}) : super(key: key);

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

  void _confirmDelete(RateAlert alert) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Alert'),
        content: Text(
          'Delete alert for ${alert.rateDisplayName} '
          '${alert.displayCondition.toLowerCase()} '
          '₹${alert.targetValue.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await context.read<AlertProvider>().deleteAlert(
                alert.id,
              );
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Alert deleted'),
                    backgroundColor: colors.secondary,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshAlerts,
        child: Consumer<AlertProvider>(
          builder: (ctx, provider, _) {
            if (provider.isLoading && provider.alerts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null) {
              return _buildError(theme, provider.errorMessage!);
            }
            if (provider.alerts.isEmpty) {
              return _buildEmpty(theme);
            }
            return _buildList(theme, provider.alerts);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.secondary,
        foregroundColor: colors.onSecondary,
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AlertCreationScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Error Loading Alerts',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              onPressed: _refreshAlerts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No Price Alerts',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first alert to get notified when '
              'prices reach your targets.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlertCreationScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Alert'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme, List<RateAlert> alerts) {
    final colors = theme.colorScheme;
    final active = alerts.where((a) => a.isActive).toList();
    final inactive = alerts.where((a) => !a.isActive).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          _section(theme, 'Active Alerts', active.length),
          const SizedBox(height: 8),
          ...active.map((a) => _card(theme, a)),
          const SizedBox(height: 24),
        ],
        if (inactive.isNotEmpty) ...[
          _section(theme, 'Inactive Alerts', inactive.length),
          const SizedBox(height: 8),
          ...inactive.map((a) => _card(theme, a)),
        ],
      ],
    );
  }

  Widget _section(ThemeData theme, String title, int count) {
    final colors = theme.colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(ThemeData theme, RateAlert alert) {
    final colors = theme.colorScheme;
    final fmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );
    final df = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alert.isActive ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.isActive ? colors.primaryContainer : colors.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        style: theme.textTheme.titleMedium?.copyWith(
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
                                : colors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${alert.displayCondition} '
                            '${fmt.format(alert.targetValue)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: alert.conditionType == 'above'
                                  ? Colors.green
                                  : colors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: alert.isActive,
                  activeColor: colors.primary, // thumb color when ON
                  activeTrackColor:
                      colors.primaryContainer, // track color when ON
                  inactiveThumbColor:
                      colors.onSurfaceVariant, // thumb color when OFF
                  inactiveTrackColor: colors.onSurfaceVariant.withOpacity(
                    0.3,
                  ), // track color when OFF
                  onChanged: (val) async {
                    final ok = await context.read<AlertProvider>().toggleAlert(
                      alert.id,
                    );
                    if (!ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.read<AlertProvider>().errorMessage ??
                                'Update failed',
                          ),
                          backgroundColor: colors.error,
                        ),
                      );
                    }
                  },
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
                        'Created: ${df.format(alert.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (alert.triggeredAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Triggered: ${df.format(alert.triggeredAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(alert),
                  icon: const Icon(Icons.delete_outline),
                  color: colors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
