import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/rates_provider.dart';
import 'screens/initialization_screen.dart';
import 'screens/graphs_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RatesProvider(),
      child: MaterialApp(
        title: 'GC Gold Rates',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        ),
        debugShowCheckedModeBanner: false,
        home: const InitializationScreen(),
        routes: {
          '/graphs': (context) => const GraphsScreen(),
        },
      ),
    );
  }
}