import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.user, super.key});

  final User user;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(user: widget.user),
      TasksScreen(user: widget.user),
      const SettingsScreen(),
    ];
    final titles = ['dashboard', 'tasks', 'settings'];

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(titles[_index]))),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  widget.user.displayName ?? context.tr('account'),
                ),
                accountEmail: Text(widget.user.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: widget.user.photoURL == null
                      ? null
                      : NetworkImage(widget.user.photoURL!),
                  child: widget.user.photoURL == null
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
              ),
              for (var i = 0; i < titles.length; i++)
                ListTile(
                  selected: _index == i,
                  leading: Icon(
                    [
                      Icons.dashboard_outlined,
                      Icons.task_alt,
                      Icons.settings_outlined,
                    ][i],
                  ),
                  title: Text(context.tr(titles[i])),
                  onTap: () {
                    setState(() => _index = i);
                    Navigator.pop(context);
                  },
                ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(context.tr('signOut')),
                onTap: AuthService.instance.signOut,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: context.tr('dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.task_alt_outlined),
            activeIcon: const Icon(Icons.task_alt),
            label: context.tr('tasks'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: context.tr('settings'),
          ),
        ],
      ),
    );
  }
}
