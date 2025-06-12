import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/rates_provider.dart';
import 'screens/main_screen.dart';
import 'screens/graphs_screen.dart';

void main() {
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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
        routes: {'/graphs': (context) => const GraphsScreen()},
      ),
    );
  }
}
