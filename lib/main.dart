import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'presentation/auth_gate.dart';
import 'presentation/auth_screen.dart';
import 'providers/app_preferences.dart';

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
      create: (_) => AppPreferences()..load(),
      child: const TaskFlowApp(),
    ),
  );
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
      routes: {'/forgot-password': (_) => const ForgotPasswordScreen()},
      home: Firebase.apps.isNotEmpty
          ? const AuthGate()
          : const _UnsupportedPlatformPage(),
    ),
  );
}

class _UnsupportedPlatformPage extends StatelessWidget {
  const _UnsupportedPlatformPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Firebase is configured for Android, iOS, and web. Run TaskFlow on one of those platforms.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
