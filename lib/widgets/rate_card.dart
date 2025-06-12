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
    final changeFormatter = NumberFormat("+#;-#", "en_IN");
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final double currentBuy = double.tryParse(card.buyRate) ?? 0;
    final double prevBuy = double.tryParse(card.previousBuyRate) ?? 0;
    final double buyChange = currentBuy - prevBuy;
    final Color buyColor = buyChange == 0
        ? Colors.grey.shade700
        : (buyChange > 0 ? Colors.green.shade600 : Colors.red.shade600);
    final IconData buyIcon = buyChange == 0
        ? Icons.remove
        : (buyChange > 0 ? Icons.arrow_upward : Icons.arrow_downward);
    final double currentSell = double.tryParse(card.sellRate) ?? 0;
    final double prevSell = double.tryParse(card.previousSellRate) ?? 0;
    final double sellChange = currentSell - prevSell;
    final Color sellColor = sellChange == 0
        ? Colors.grey.shade700
        : (sellChange > 0 ? Colors.green.shade600 : Colors.red.shade600);
    final IconData sellIcon = sellChange == 0
        ? Icons.remove
        : (sellChange > 0 ? Icons.arrow_upward : Icons.arrow_downward);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  GraphsScreen(initialSeriesSymbol: card.apiSymbol),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: colorScheme.secondaryContainer.withOpacity(0.4),
              child: Text(
                card.title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildRateColumn(
                      'BUY',
                      card.buyRate,
                      buyChange,
                      buyColor,
                      buyIcon,
                      currencyFormatter,
                      changeFormatter,
                      textTheme,
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    indent: 10,
                    endIndent: 10,
                  ),
                  Expanded(
                    child: _buildRateColumn(
                      'SELL',
                      card.sellRate,
                      sellChange,
                      sellColor,
                      sellIcon,
                      currencyFormatter,
                      changeFormatter,
                      textTheme,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHighLowStat(
                    'Low',
                    card.low,
                    currencyFormatter,
                    textTheme,
                    Colors.red.shade800,
                  ),
                  _buildHighLowStat(
                    'High',
                    card.high,
                    currencyFormatter,
                    textTheme,
                    Colors.green.shade800,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateColumn(
    String label,
    String rate,
    double change,
    Color color,
    IconData icon,
    NumberFormat currencyFormatter,
    NumberFormat changeFormatter,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormatter.format(double.tryParse(rate) ?? 0),
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

  Widget _buildHighLowStat(
    String label,
    String value,
    NumberFormat formatter,
    TextTheme textTheme,
    Color color,
  ) {
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: formatter.format(double.tryParse(value) ?? 0),
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
