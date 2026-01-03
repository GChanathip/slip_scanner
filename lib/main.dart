import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Payment Slip Scanner',
      debugShowCheckedModeBanner: false,
      theme: ShadThemeData(brightness: Brightness.light, colorScheme: const ShadZincColorScheme.light()),
      darkTheme: ShadThemeData(brightness: Brightness.dark, colorScheme: const ShadZincColorScheme.dark()),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
