import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'providers/rates_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/theme_provider.dart' as custom_theme;
import 'screens/initialization_screen.dart';

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
            themeMode:
                ThemeMode.values[custom_theme.AppThemeMode.values.indexOf(
                  themeProvider.themeMode,
                )],
            home: const InitializationScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
