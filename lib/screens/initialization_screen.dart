import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rates_provider.dart';
import '../providers/theme_provider.dart' as custom_theme;
import '../services/notification_service.dart';
import '../widgets/cool_loader.dart';
import 'main_screen.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    setState(() {
      _error = null;
    });

    try {
      // Initialize theme first
      final themeProvider = context.read<custom_theme.ThemeProvider>();
      await themeProvider.initializeTheme();

      // Initialize notifications
      await NotificationService().initNotifications();

      // Initialize and fetch rates
      if (mounted) {
        final ratesProvider = context.read<RatesProvider>();
        await ratesProvider.initializeAndFetch();
      }

      // Navigate to main screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: _error == null
            ? const CoolLoader(
                loadingText: 'Loading GC Gold Rates...',
                size: 140.0,
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 60,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connection Error',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error ?? 'An unknown error occurred.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _initializeApp,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
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
