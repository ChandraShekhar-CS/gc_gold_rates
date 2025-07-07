import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/rate_card.dart' as model;
import '../screens/graphs_screen.dart';

class RateCardWidget extends StatelessWidget {
  final model.RateCard card;
  const RateCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );
    final changeFormatter = NumberFormat('+#;-#', 'en_IN');

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Parse rates
    final currentBuy = double.tryParse(card.buyRate) ?? 0;
    final prevBuy = double.tryParse(card.previousBuyRate) ?? 0;
    final buyChange = currentBuy - prevBuy;
    final buyColor = buyChange == 0
        ? colors.onSurfaceVariant
        : (buyChange > 0 ? colors.secondary : colors.error);
    final buyIcon = buyChange == 0
        ? Icons.remove
        : (buyChange > 0 ? Icons.arrow_upward : Icons.arrow_downward);

    final currentSell = double.tryParse(card.sellRate) ?? 0;
    final prevSell = double.tryParse(card.previousSellRate) ?? 0;
    final sellChange = currentSell - prevSell;
    final sellColor = sellChange == 0
        ? colors.onSurfaceVariant
        : (sellChange > 0 ? colors.secondary : colors.error);
    final sellIcon = sellChange == 0
        ? Icons.remove
        : (sellChange > 0 ? Icons.arrow_upward : Icons.arrow_downward);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GraphsScreen(initialSeriesSymbol: card.apiSymbol),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: colors.primaryContainer,
              child: Text(
                card.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildRateColumn(
                      label: 'BUY',
                      amount: currentBuy,
                      change: buyChange,
                      color: buyColor,
                      icon: buyIcon,
                      currencyFormatter: currencyFormatter,
                      changeFormatter: changeFormatter,
                      textTheme: textTheme,
                      onSurfaceVariant: colors.onSurfaceVariant,
                    ),
                  ),
                  VerticalDivider(
                    color: colors.outline,
                    width: 1,
                    thickness: 1,
                  ),
                  Expanded(
                    child: _buildRateColumn(
                      label: 'SELL',
                      amount: currentSell,
                      change: sellChange,
                      color: sellColor,
                      icon: sellIcon,
                      currencyFormatter: currencyFormatter,
                      changeFormatter: changeFormatter,
                      textTheme: textTheme,
                      onSurfaceVariant: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: colors.outline, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHighLow(
                    label: 'Low',
                    value: double.tryParse(card.low) ?? 0,
                    formatter: currencyFormatter,
                    textTheme: textTheme,
                    color: colors.error,
                    onSurfaceVariant: colors.onSurfaceVariant,
                  ),
                  _buildHighLow(
                    label: 'High',
                    value: double.tryParse(card.high) ?? 0,
                    formatter: currencyFormatter,
                    textTheme: textTheme,
                    color: colors.secondary,
                    onSurfaceVariant: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateColumn({
    required String label,
    required double amount,
    required double change,
    required Color color,
    required IconData icon,
    required NumberFormat currencyFormatter,
    required NumberFormat changeFormatter,
    required TextTheme textTheme,
    required Color onSurfaceVariant,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormatter.format(amount),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                changeFormatter.format(change),
                style: textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighLow({
    required String label,
    required double value,
    required NumberFormat formatter,
    required TextTheme textTheme,
    required Color color,
    required Color onSurfaceVariant,
  }) {
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: formatter.format(value),
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
