import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rates_provider.dart';
import '../widgets/rate_card.dart';
import 'graphs_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GC Gold Rates'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<RatesProvider>(context, listen: false).fetchRates();
        },
        child: Consumer<RatesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.rateCards.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null && provider.rateCards.isEmpty) {
              return Center(child: Text('Error: ${provider.errorMessage}'));
            }
            if (provider.rateCards.isEmpty) {
              return const Center(child: Text('No rate cards configured.'));
            }
            return ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.rateCards.length,
              itemBuilder: (context, index) {
                final card = provider.rateCards[index];
                return RateCardWidget(key: ValueKey(card.uniqueId), card: card);
              },
              onReorder: (oldIndex, newIndex) {
                provider.reorderCards(oldIndex, newIndex);
              },
            );
          },
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.amber.shade700),
            child: const Text(
              'Navigation',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Live Rates'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('Graphs'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/graphs');
            },
          ),
        ],
      ),
    );
  }
}
