import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:provider/provider.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppPreferences(),
      child: const TaskFlowApp(),
    ),
  );
}

class AppPreferences extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AppPreferences>(
        builder: (context, preferences, _) => MaterialApp(
          title: 'TaskFlow',
          debugShowCheckedModeBanner: false,
          themeMode: preferences.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF536DFE)),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8C9EFF),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          routes: {
            '/': (_) => const HomePage(),
            '/tasks': (_) => const PlaceholderPage(title: 'Tasks'),
            '/calendar': (_) => const PlaceholderPage(title: 'Calendar'),
            '/profile': (_) => const PlaceholderPage(title: 'Profile'),
          },
          initialRoute: '/',
        ),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppPreferences>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: preferences.toggleTheme,
            icon: Icon(preferences.themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('Your day, in flow.',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Your TaskFlow workspace is ready.',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/tasks'),
                icon: const Icon(Icons.checklist),
                label: const Text('Open tasks'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (index) => Navigator.pushReplacementNamed(
          context,
          ['/', '/tasks', '/calendar', '/profile'][index],
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text('$title screen is ready for implementation.')),
      );
}
