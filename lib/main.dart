import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'providers/rates_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/theme_provider.dart' as custom_theme;
import 'screens/initialization_screen.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => custom_theme.ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RatesProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
      ],
      child: Consumer<custom_theme.ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'GC Gold Rates',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: _getFlutterThemeMode(themeProvider.themeMode),
            home: const InitializationScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeMode _getFlutterThemeMode(custom_theme.ThemeMode customThemeMode) {
    switch (customThemeMode) {
      case custom_theme.ThemeMode.light:
        return ThemeMode.light;
      case custom_theme.ThemeMode.dark:
        return ThemeMode.dark;
      case custom_theme.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}