import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/app_preferences.dart';
import '../repositories/task_repository.dart';
import '../services/reminder_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.user, super.key});

  final User user;

  Future<void> _setNotifications(
    BuildContext context,
    AppPreferences preferences,
    bool enabled,
  ) async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await preferences.setNotificationsEnabled(enabled);
    var scheduled = false;
    try {
      final repository = TaskRepository(userId: user.uid);
      scheduled = await ReminderService.instance.syncTasks(
        userId: user.uid,
        tasks: await repository.watchTasks().first,
        reminderTitle: strings.get('taskReminder'),
        bodyFor: (title) => strings.get('reminderBody', {'title': title}),
      );
    } catch (_) {
      scheduled = false;
    }
    if (!scheduled && context.mounted) {
      await preferences.setNotificationsEnabled(false);
      messenger.showSnackBar(
        SnackBar(content: Text(strings.get('notificationPermissionDenied'))),
      );
    }
  }

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
            onChanged: (value) =>
                _setNotifications(context, preferences, value),
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
