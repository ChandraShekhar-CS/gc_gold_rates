import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum representing available theme modes.
enum AppThemeMode { system, light, dark }

/// A provider that manages and persists the application's theme settings.
class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'app_theme_mode';
  AppThemeMode _mode = AppThemeMode.system;
  bool _initialized = false;

  /// Returns the current theme mode.
  AppThemeMode get themeMode => _mode;

  /// Indicates whether the dark theme is active.
  bool get isDark {
    if (_mode == AppThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _mode == AppThemeMode.dark;
  }

  /// Indicates whether the provider has loaded saved preferences.
  bool get initialized => _initialized;

  /// Alias for init()
  Future<void> initializeTheme() => init();

  /// Light theme for MaterialApp.theme
  ThemeData get lightTheme => _buildLightTheme();

  /// Dark theme for MaterialApp.darkTheme
  ThemeData get darkTheme => _buildDarkTheme();

  /// Initializes the provider by loading the saved theme mode.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      _mode = AppThemeMode.values.firstWhere(
        (m) => m.toString() == saved,
        orElse: () => AppThemeMode.system,
      );
    }
    _initialized = true;
    notifyListeners();
  }

  /// Updates the theme mode and persists the choice.
  Future<void> setMode(AppThemeMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newMode.toString());
  }

  /// Provides the appropriate [ThemeData] based on [isDark].
  ThemeData get themeData => isDark ? _buildDarkTheme() : _buildLightTheme();

  /// Light theme configuration.
  ThemeData _buildLightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(0xFFE16B3B),
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: scheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) =>
              states.contains(MaterialState.selected) ? scheme.primary : null,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? scheme.primary.withOpacity(0.5)
              : null,
        ),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: scheme.onSurfaceVariant,
        selectedColor: scheme.onPrimary,
        fillColor: scheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// Dark theme configuration.
  ThemeData _buildDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: scheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.secondary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.secondary,
          side: BorderSide(color: scheme.secondary),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.secondary,
        unselectedItemColor: scheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? scheme.secondary
              : scheme.onSurfaceVariant,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? scheme.secondary.withOpacity(0.5)
              : scheme.onSurfaceVariant,
        ),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: scheme.onSurfaceVariant,
        selectedColor: scheme.onSurface,
        fillColor: scheme.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
