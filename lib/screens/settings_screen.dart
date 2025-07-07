import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_selection_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_outlined, color: colors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Appearance',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer<ThemeProvider>(
                  builder: (_, themeProvider, __) {
                    String label;
                    IconData icon;
                    switch (themeProvider.themeMode) {
                      case AppThemeMode.light:
                        label = 'Light Theme';
                        icon = Icons.light_mode;
                        break;
                      case AppThemeMode.dark:
                        label = 'Dark Theme';
                        icon = Icons.dark_mode;
                        break;
                      case AppThemeMode.system:
                      default:
                        label = 'System Default';
                        icon = Icons.settings_brightness;
                        break;
                    }
                    return ListTile(
                      leading: Icon(icon),
                      title: const Text('Theme'),
                      subtitle: Text(label),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const ThemeSelectionDialog(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'About',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.apps),
                  title: const Text('App Version'),
                  subtitle: const Text('4.1'),
                ),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Developer'),
                  subtitle: const Text('GC Gold Rates Team'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
