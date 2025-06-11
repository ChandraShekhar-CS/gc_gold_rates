// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rates_provider.dart';
import '../widgets/rate_card_widget.dart'; 
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
        // The onRefresh callback expects a Future.
        // Using a lambda ensures a Future is returned correctly.
        onRefresh: () async {
          await Provider.of<RatesProvider>(context, listen: false).fetchRates();
        },
        child: Consumer<RatesProvider>(
          builder: (context, provider, child) {
            // Show loading indicator on initial load
            if (provider.isLoading && provider.rateCards.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            // Show error message if fetching fails on initial load
            if (provider.errorMessage != null && provider.rateCards.isEmpty) {
              return Center(child: Text('Error: ${provider.errorMessage}'));
            }
            // Handle case where cards might be empty for other reasons
            if (provider.rateCards.isEmpty) {
                return const Center(child: Text('No rate cards configured.'));
            }

            // Using ReorderableListView for drag-and-drop functionality
            return ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.rateCards.length,
              itemBuilder: (context, index) {
                final card = provider.rateCards[index];
                // A Key is crucial for ReorderableListView to work correctly.
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

/// A simple drawer for navigating to other screens.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
            ),
            child: const Text(
              'Navigation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Live Rates'),
            onTap: () {
              // Close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('Graphs'),
            onTap: () {
              // Navigate to the Graphs screen
              Navigator.pop(context); // Close the drawer first
              Navigator.pushNamed(context, '/graphs');
            },
          ),
        ],
      ),
    );
  }
}
