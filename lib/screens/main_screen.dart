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
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _indicatorAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    _animationController.forward().then((_) {
      _animationController.reset();
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Price Alerts'),
          content: const Text(
              'Price alerts feature coming soon!\n\nYou\'ll be able to set custom notifications when gold and silver prices reach your target levels.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildLiveRatesPage(),
          _buildGraphsPage(),
          _buildAlertsPage(),
        ],
      ),
      bottomNavigationBar: _buildAdvancedBottomNavigation(),
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

  Widget _buildAdvancedBottomNavigation() {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Floating Indicator (like your CSS) with better contrast
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top: -25,
            left: _getIndicatorPosition(),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade500,
                    Colors.amber.shade700,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF151F28), width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade300.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Navigation Items
          Row(
            children: [
              _buildAdvancedNavItem(0, Icons.home_outlined, 'Live Rates'),
              _buildAdvancedNavItem(1, Icons.trending_up_outlined, 'Charts'),
              _buildAdvancedNavItem(2, Icons.notifications_outlined, 'Alerts'),
            ],
          ),
        ],
      ),
    );
  }

  double _getIndicatorPosition() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth - 32;
    final itemWidth = containerWidth / 3;
    return (_selectedIndex * itemWidth) + (itemWidth / 2) - 35;
  }

  Widget _buildAdvancedNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with smooth animation and better contrast
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                transform: Matrix4.identity()
                  ..translate(0.0, isSelected ? -32.0 : 0.0),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    icon,
                    size: isSelected ? 26 : 24,
                    color: isSelected 
                        ? const Color(0xFF151F28) // Dark color for better contrast
                        : const Color(0xFF151F28),
                    shadows: isSelected ? [
                      const Shadow(
                        color: Colors.white,
                        blurRadius: 2,
                        offset: Offset(0, 0),
                      ),
                    ] : null,
                  ),
                ),
              ),
              // Text with fade animation
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: isSelected ? 1.0 : 0.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  transform: Matrix4.identity()
                    ..translate(0.0, isSelected ? 10.0 : 20.0),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF151F28),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom clipper for the indicator curves (like CSS before/after)
class _IndicatorClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    ));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Separate content widget for graphs to avoid rebuilding
class GraphsScreenContent extends StatelessWidget {
  const GraphsScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const GraphsScreen();
  }
}