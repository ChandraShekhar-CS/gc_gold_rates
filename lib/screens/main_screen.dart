import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rates_provider.dart';
import '../widgets/rate_card.dart';
import 'graphs_screen.dart';
import 'alert_management_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'GC Gold Rates';
      case 1:
        return 'Charts';
      case 2:
        return 'Price Alerts';
      case 3:
        return 'Settings';
      default:
        return 'GC Gold Rates';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            _buildLiveRatesPage(),
            _buildGraphsPage(),
            _buildAlertsPage(),
            _buildSettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Rates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Charts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRatesPage() {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<RatesProvider>(context, listen: false).fetchRates();
      },
      child: Consumer<RatesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.rateCards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.rateCards.isEmpty) {
            return const Center(child: Text('No rate cards available.'));
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: 20,
            ),
            itemCount: provider.rateCards.length,
            itemBuilder: (context, index) {
              final card = provider.rateCards[index];
              return RateCardWidget(
                  key: ValueKey(card.uniqueId), card: card);
            },
            onReorder: (oldIndex, newIndex) {
              provider.reorderCards(oldIndex, newIndex);
            },
          );
        },
      ),
    );
  }

  Widget _buildGraphsPage() {
    return const GraphsScreenContent();
  }

  Widget _buildAlertsPage() {
    return const AlertManagementScreen();
  }

  Widget _buildSettingsPage() {
    return const SettingsScreenContent();
  }
}

class GraphsScreenContent extends StatelessWidget {
  const GraphsScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const GraphsScreen();
  }
}

class SettingsScreenContent extends StatelessWidget {
  const SettingsScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}