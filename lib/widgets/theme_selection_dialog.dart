import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final currentMode = themeProvider.themeMode;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Select Theme', style: textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: AppThemeMode.values.map((mode) {
          return RadioListTile<AppThemeMode>(
            value: mode,
            groupValue: currentMode,
            activeColor: colors.primary,
            title: Text(_modeLabel(mode)),
            onChanged: (m) {
              if (m != null) {
                themeProvider.setMode(m);
                Navigator.of(context).pop();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  String _modeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light Theme';
      case AppThemeMode.dark:
        return 'Dark Theme';
      case AppThemeMode.system:
      default:
        return 'System Default';
    }
  }
}
