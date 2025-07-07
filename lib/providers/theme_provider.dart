import 'package:flutter/material.dart' hide ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> initializeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }

  ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.amber,
      secondary: Colors.green,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.amber.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.amber.shade700,
      foregroundColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.amber.shade700;
        }
        return null;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.amber.shade300;
        }
        return null;
      }),
    ),
    toggleButtonsTheme: ToggleButtonsThemeData(
      selectedBorderColor: Colors.amber.shade700,
      selectedColor: Colors.white,
      fillColor: Colors.amber.shade700,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF343434),
      onPrimary: const Color(0xFFFFFFFF),
      secondary: const Color(0xFF32D74B),
      onSecondary: const Color(0xFFFFFFFF),
      error: const Color(0xFFFF453A),
      onError: const Color(0xFFFFFFFF),
      background: const Color(0xFF121212),
      onBackground: const Color(0xFFFFFFFF),
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFFFFFFF),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    dividerColor: const Color(0xFF2C2C2C),
    disabledColor: const Color(0xFF666666),
    hoverColor: const Color(0xFF2A2A2A),
    highlightColor: const Color(0xFF383838),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Color(0xFFFFFFFF),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: const Color(0xFF000000),
        disabledBackgroundColor: const Color(0xFF666666),
        disabledForegroundColor: const Color(0xFF383838),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFFFD700),
      foregroundColor: const Color(0xFF000000),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFFFFD700);
        }
        return const Color(0xFF666666);
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF2C2C2C);
        }
        return const Color(0xFF2C2C2C);
      }),
    ),
    toggleButtonsTheme: ToggleButtonsThemeData(
      selectedBorderColor: const Color(0xFFFFD700),
      selectedColor: const Color(0xFF000000),
      fillColor: const Color(0xFFFFD700),
      borderColor: const Color(0xFF2C2C2C),
      color: const Color(0xFFB3B3B3),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: const Color(0xFFFFD700),
      unselectedItemColor: const Color(0xFFB3B3B3),
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFFFFFFF)),
      bodyMedium: TextStyle(color: Color(0xFFB3B3B3)),
      bodySmall: TextStyle(color: Color(0xFF666666)),
    ),
  );
}
