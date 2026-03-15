import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/payment_slip.dart';
import '../screens/home_screen.dart';
import '../screens/monthly_view_screen.dart';
import '../screens/scanning_progress_screen.dart';
import '../screens/slip_detail_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/server_dashboard_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/category_management_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.cupertino();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: ScanningProgressRoute.page),
        AutoRoute(page: SlipDetailRoute.page),
        AutoRoute(page: MonthlyViewRoute.page),
        AutoRoute(page: AnalysisRoute.page),
        AutoRoute(page: ChatRoute.page),
        AutoRoute(page: SettingsRoute.page),
        AutoRoute(page: CategoryManagementRoute.page),
        AutoRoute(page: ServerDashboardRoute.page),
      ];
}

