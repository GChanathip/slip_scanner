import 'dart:io' show Platform;

import 'package:auto_route/auto_route.dart';
import 'package:avers/core/services/notification_service.dart';
import 'package:avers/router/app_router.dart';
import 'package:cactus/cactus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CactusConfig.setTelemetryToken('f048d96d-ab22-41ed-b5c1-8226b3300315');
  await NotificationService.instance.initialize();
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
    return MaterialApp.router(
      title: 'Avers',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', 'US'),
      localizationsDelegates: FLocalizations.localizationsDelegates,
      supportedLocales: FLocalizations.supportedLocales,
      theme: FThemes.zinc.light.toApproximateMaterialTheme(),
      darkTheme: FThemes.zinc.dark.toApproximateMaterialTheme(),
      builder: (context, child) {
        final brightness = MediaQuery.platformBrightnessOf(context);
        final theme = brightness == Brightness.dark ? FThemes.zinc.dark : FThemes.zinc.light;
        return FTheme(
          data: theme,
          child: FToaster(child: child!),
        );
      },
      routerConfig: _appRouter.config(
        deepLinkBuilder: (_) => Platform.isMacOS
            ? DeepLink.single(const ServerDashboardRoute())
            : DeepLink.defaultPath,
      ),
    );
  }
}
