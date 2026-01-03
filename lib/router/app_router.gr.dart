// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [MonthlyViewScreen]
class MonthlyViewRoute extends PageRouteInfo<MonthlyViewRouteArgs> {
  MonthlyViewRoute({
    Key? key,
    required DateTime month,
    List<PageRouteInfo>? children,
  }) : super(
         MonthlyViewRoute.name,
         args: MonthlyViewRouteArgs(key: key, month: month),
         initialChildren: children,
       );

  static const String name = 'MonthlyViewRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MonthlyViewRouteArgs>();
      return MonthlyViewScreen(key: args.key, month: args.month);
    },
  );
}

class MonthlyViewRouteArgs {
  const MonthlyViewRouteArgs({this.key, required this.month});

  final Key? key;

  final DateTime month;

  @override
  String toString() {
    return 'MonthlyViewRouteArgs{key: $key, month: $month}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MonthlyViewRouteArgs) return false;
    return key == other.key && month == other.month;
  }

  @override
  int get hashCode => key.hashCode ^ month.hashCode;
}

/// generated route for
/// [ScanningProgressScreen]
class ScanningProgressRoute extends PageRouteInfo<void> {
  const ScanningProgressRoute({List<PageRouteInfo>? children})
    : super(ScanningProgressRoute.name, initialChildren: children);

  static const String name = 'ScanningProgressRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ScanningProgressScreen();
    },
  );
}

/// generated route for
/// [SlipDetailScreen]
class SlipDetailRoute extends PageRouteInfo<SlipDetailRouteArgs> {
  SlipDetailRoute({
    Key? key,
    required PaymentSlip slip,
    List<PageRouteInfo>? children,
  }) : super(
         SlipDetailRoute.name,
         args: SlipDetailRouteArgs(key: key, slip: slip),
         initialChildren: children,
       );

  static const String name = 'SlipDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SlipDetailRouteArgs>();
      return SlipDetailScreen(key: args.key, slip: args.slip);
    },
  );
}

class SlipDetailRouteArgs {
  const SlipDetailRouteArgs({this.key, required this.slip});

  final Key? key;

  final PaymentSlip slip;

  @override
  String toString() {
    return 'SlipDetailRouteArgs{key: $key, slip: $slip}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SlipDetailRouteArgs) return false;
    return key == other.key && slip == other.slip;
  }

  @override
  int get hashCode => key.hashCode ^ slip.hashCode;
}
