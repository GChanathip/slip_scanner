import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:avers/core/models/payment_slip.dart';
import 'package:avers/features/home/pages/home_screen.dart';
import 'package:avers/features/slip/pages/monthly_view_screen.dart';
import 'package:avers/features/scanning/pages/scanning_progress_screen.dart';
import 'package:avers/features/slip/pages/slip_detail_screen.dart';
import 'package:avers/features/analysis/pages/analysis_screen.dart';
import 'package:avers/features/chat/pages/chat_screen.dart';
import 'package:avers/features/server/pages/server_dashboard_screen.dart';
import 'package:avers/features/settings/pages/settings_screen.dart';
import 'package:avers/features/category/pages/category_management_screen.dart';

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

