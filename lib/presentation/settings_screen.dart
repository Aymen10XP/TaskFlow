import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/app_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppPreferences>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionTitle(context.tr('appearance')),
        const SizedBox(height: 10),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(
              value: ThemeMode.light,
              icon: const Icon(Icons.light_mode_outlined),
              label: Text(context.tr('light')),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: const Icon(Icons.settings_suggest_outlined),
              label: Text(context.tr('system')),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: const Icon(Icons.dark_mode_outlined),
              label: Text(context.tr('dark')),
            ),
          ],
          selected: {preferences.themeMode},
          onSelectionChanged: (selection) =>
              preferences.setThemeMode(selection.first),
        ),
        const SizedBox(height: 28),
        _SectionTitle(context.tr('language')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: preferences.locale.languageCode,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.language),
            border: const OutlineInputBorder(),
            labelText: context.tr('language'),
          ),
          items: [
            DropdownMenuItem(value: 'fr', child: Text(context.tr('french'))),
            DropdownMenuItem(value: 'en', child: Text(context.tr('english'))),
            DropdownMenuItem(value: 'ar', child: Text(context.tr('arabic'))),
          ],
          onChanged: (value) {
            if (value != null) preferences.setLocale(Locale(value));
          },
        ),
        const SizedBox(height: 28),
        _SectionTitle(context.tr('notifications')),
        const SizedBox(height: 10),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(context.tr('notifications')),
            subtitle: Text(context.tr('notificationsHint')),
            value: preferences.notificationsEnabled,
            onChanged: preferences.setNotificationsEnabled,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge);
}
