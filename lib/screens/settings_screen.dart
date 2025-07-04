import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart' as theme_provider;
import '../widgets/theme_selection_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildAppearanceSection(context),
        const SizedBox(height: 24),
        _buildAboutSection(context),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<theme_provider.ThemeProvider>(
              builder: (context, themeProvider, child) {
                String currentThemeText;
                IconData currentThemeIcon;
                
                switch (themeProvider.themeMode) {
                  case theme_provider.ThemeMode.light:
                    currentThemeText = 'Light Theme';
                    currentThemeIcon = Icons.light_mode;
                    break;
                  case theme_provider.ThemeMode.dark:
                    currentThemeText = 'Dark Theme';
                    currentThemeIcon = Icons.dark_mode;
                    break;
                  case theme_provider.ThemeMode.system:
                    currentThemeText = 'System Default';
                    currentThemeIcon = Icons.settings_brightness;
                    break;
                }
                
                return ListTile(
                  leading: Icon(currentThemeIcon),
                  title: const Text('Theme'),
                  subtitle: Text(currentThemeText),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ThemeSelectionDialog(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('App Version'),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Developer'),
              subtitle: const Text('GC Gold Rates Team'),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.launch),
              onTap: () {
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.launch),
              onTap: () {
              },
            ),
          ],
        ),
      ),
    );
  }
}