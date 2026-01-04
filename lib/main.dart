import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'router/app_router.dart';
import 'package:cactus/cactus.dart';

void main() {
  CactusConfig.setTelemetryToken('f048d96d-ab22-41ed-b5c1-8226b3300315');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return ShadApp.router(
      title: 'Payment Slip Scanner',
      debugShowCheckedModeBanner: false,
      theme: ShadThemeData(brightness: Brightness.light, colorScheme: const ShadZincColorScheme.light()),
      darkTheme: ShadThemeData(brightness: Brightness.dark, colorScheme: const ShadZincColorScheme.dark()),
      themeMode: ThemeMode.system,
      routerConfig: _appRouter.config(),
    );
  }
}
