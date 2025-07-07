import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/rates_provider.dart';
import '../widgets/rate_card.dart';
import 'graphs_screen.dart';
import 'alert_management_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  String _chartSeries = 'gold';
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _autoRefreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoRefresh();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
      _refreshRates();
    } else if (state == AppLifecycleState.paused) {
      _stopAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    _stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (_currentIndex == 0 && mounted) _refreshRates();
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void _refreshRates() {
    if (mounted) context.read<RatesProvider>().fetchRates();
  }

  /// Switch to Charts tab *and* set which series it should display.
  void switchToChartsTab(String series) {
    setState(() {
      _chartSeries = series;
      _currentIndex = 1;
    });
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _stopAutoRefresh();
  }

  void _onBottomNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    if (index == 0)
      _startAutoRefresh();
    else
      _stopAutoRefresh();
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: _currentIndex == 0
            ? [
                Consumer<RatesProvider>(
                  builder: (_, provider, __) {
                    return IconButton(
                      icon: provider.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Icon(Icons.refresh, color: colors.onPrimary),
                      onPressed: provider.isLoading ? null : _refreshRates,
                    );
                  },
                ),
              ]
            : null,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: (i) {
            setState(() => _currentIndex = i);
            if (i == 0)
              _startAutoRefresh();
            else
              _stopAutoRefresh();
          },
          children: [
            const _LiveRatesPage(),
            // pass our mutable chart symbol here
            GraphsScreen(initialSeriesSymbol: _chartSeries),
            const AlertManagementScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurface.withOpacity(0.6),
        backgroundColor: colors.surface,
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
}

class _LiveRatesPage extends StatelessWidget {
  const _LiveRatesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async => context.read<RatesProvider>().fetchRates(),
      child: Consumer<RatesProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.rateCards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                    ),
                    onPressed: () => context.read<RatesProvider>().fetchRates(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.rateCards.isEmpty) {
            return const Center(child: Text('No rate cards available.'));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
            itemCount: provider.rateCards.length,
            itemBuilder: (_, index) {
              final card = provider.rateCards[index];
              return RateCardWidget(key: ValueKey(card.uniqueId), card: card);
            },
            onReorder: provider.reorderCards,
          );
        },
      ),
    );
  }
}
