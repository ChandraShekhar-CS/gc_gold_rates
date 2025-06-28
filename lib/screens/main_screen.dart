import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rates_provider.dart';
import '../widgets/rate_card.dart';
import 'graphs_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Track which icons should animate
  Set<int> _animatingIcons = {};
  Map<int, AnimationController> _iconAnimationControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    // Initialize animation controllers for each tab
    for (int i = 0; i < 3; i++) {
      _iconAnimationControllers[i] = AnimationController(
        duration: const Duration(milliseconds: 800), // Duration for one GIF cycle
        vsync: this,
      );
    }
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    // Dispose all icon animation controllers
    for (var controller in _iconAnimationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    // Trigger animation for the tapped icon
    setState(() {
      _animatingIcons.add(index);
    });
    
    // Start the animation and stop it after one cycle
    _iconAnimationControllers[index]?.reset();
    _iconAnimationControllers[index]?.forward().then((_) {
      if (mounted) {
        setState(() {
          _animatingIcons.remove(index);
        });
      }
    });

    setState(() {
      _selectedIndex = index;
    });

    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildLiveRatesPage(),
            _buildGraphsPage(),
            _buildAlertsPage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildSmoothBottomNavigation(),
    );
  }

  Widget _buildLiveRatesPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GC Gold Rates'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
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
      ),
    );
  }

  Widget _buildGraphsPage() {
    return const GraphsScreenContent();
  }

  Widget _buildAlertsPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Alerts'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Price Alerts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Set up custom alerts to get notified when gold and silver prices reach your target levels.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmoothBottomNavigation() {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              top: 8,
              bottom: 8,
              left: _getIndicatorPosition(),
              width: _getIndicatorWidth(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade400,
                      Colors.amber.shade600,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                _buildNavItem(
                  index: 0,
                  staticIconPath: 'assets/animations/home_static.png',
                  animatedIconPath: 'assets/animations/home_icon.gif',
                  fallbackIcon: Icons.home,
                  label: 'Rates',
                ),
                _buildNavItem(
                  index: 1,
                  staticIconPath: 'assets/animations/chart_static.png',
                  animatedIconPath: 'assets/animations/chart_icon.gif',
                  fallbackIcon: Icons.trending_up,
                  label: 'Charts',
                ),
                _buildNavItem(
                  index: 2,
                  staticIconPath: 'assets/animations/bell_static.png',
                  animatedIconPath: 'assets/animations/bell_icon.gif',
                  fallbackIcon: Icons.notifications,
                  label: 'Alerts',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getIndicatorPosition() {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 3;
    return (_selectedIndex * itemWidth) + (itemWidth * 0.15);
  }

  double _getIndicatorWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 3;
    return itemWidth * 0.7;
  }

  Widget _buildNavItem({
    required int index,
    required String staticIconPath,
    required String animatedIconPath,
    required IconData fallbackIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final isAnimating = _animatingIcons.contains(index);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Container(
                  width: 28,
                  height: 28,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    child: isAnimating
                        ? ColorFiltered(
                            key: ValueKey('animated_$index'),
                            colorFilter: isSelected 
                              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                              : ColorFilter.mode(Colors.grey.shade600, BlendMode.srcIn),
                            child: Image.asset(
                              animatedIconPath,
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  fallbackIcon,
                                  size: 28,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                );
                              },
                            ),
                          )
                        : ColorFiltered(
                            key: ValueKey('static_$index'),
                            colorFilter: isSelected 
                              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                              : ColorFilter.mode(Colors.grey.shade600, BlendMode.srcIn),
                            child: Image.asset(
                              staticIconPath,
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  fallbackIcon,
                                  size: 28,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GraphsScreenContent extends StatelessWidget {
  const GraphsScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const GraphsScreen();
  }
}