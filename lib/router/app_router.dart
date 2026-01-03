import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/payment_slip.dart';
import '../screens/home_screen.dart';
import '../screens/monthly_view_screen.dart';
import '../screens/scanning_progress_screen.dart';
import '../screens/slip_detail_screen.dart';

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
      ];
}

