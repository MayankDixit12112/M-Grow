import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'l10n.dart';
import 'onboarding_screen.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  L10n.lang.value = Storage.language() ?? 'en';
  runApp(const MGrowApp());
}

class MGrowApp extends StatelessWidget {
  const MGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2E9E6B);
    return MaterialApp(
      title: 'M Grow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: seed),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
      ),
      home: Storage.loadProfile() == null
          ? const OnboardingScreen()
          : const HomeScreen(),
    );
  }
}
