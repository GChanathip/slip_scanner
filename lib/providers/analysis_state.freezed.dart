// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InsightData {

 String get title; String get description; String get type;// 'trend', 'anomaly', 'suggestion'
 double? get value; String? get icon;
/// Create a copy of InsightData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightDataCopyWith<InsightData> get copyWith => _$InsightDataCopyWithImpl<InsightData>(this as InsightData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsightData&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,type,value,icon);

@override
String toString() {
  return 'InsightData(title: $title, description: $description, type: $type, value: $value, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $InsightDataCopyWith<$Res>  {
  factory $InsightDataCopyWith(InsightData value, $Res Function(InsightData) _then) = _$InsightDataCopyWithImpl;
@useResult
$Res call({
 String title, String description, String type, double? value, String? icon
});




}
/// @nodoc
class _$InsightDataCopyWithImpl<$Res>
    implements $InsightDataCopyWith<$Res> {
  _$InsightDataCopyWithImpl(this._self, this._then);

  final InsightData _self;
  final $Res Function(InsightData) _then;

/// Create a copy of InsightData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? type = null,Object? value = freezed,Object? icon = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InsightData].
extension InsightDataPatterns on InsightData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InsightData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InsightData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InsightData value)  $default,){
final _that = this;
switch (_that) {
case _InsightData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InsightData value)?  $default,){
final _that = this;
switch (_that) {
case _InsightData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description,  String type,  double? value,  String? icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InsightData() when $default != null:
return $default(_that.title,_that.description,_that.type,_that.value,_that.icon);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description,  String type,  double? value,  String? icon)  $default,) {final _that = this;
switch (_that) {
case _InsightData():
return $default(_that.title,_that.description,_that.type,_that.value,_that.icon);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description,  String type,  double? value,  String? icon)?  $default,) {final _that = this;
switch (_that) {
case _InsightData() when $default != null:
return $default(_that.title,_that.description,_that.type,_that.value,_that.icon);case _:
  return null;

}
}

}

/// @nodoc


class _InsightData implements InsightData {
  const _InsightData({required this.title, required this.description, required this.type, this.value, this.icon});
  

@override final  String title;
@override final  String description;
@override final  String type;
// 'trend', 'anomaly', 'suggestion'
@override final  double? value;
@override final  String? icon;

/// Create a copy of InsightData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightDataCopyWith<_InsightData> get copyWith => __$InsightDataCopyWithImpl<_InsightData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InsightData&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,type,value,icon);

@override
String toString() {
  return 'InsightData(title: $title, description: $description, type: $type, value: $value, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$InsightDataCopyWith<$Res> implements $InsightDataCopyWith<$Res> {
  factory _$InsightDataCopyWith(_InsightData value, $Res Function(_InsightData) _then) = __$InsightDataCopyWithImpl;
@override @useResult
$Res call({
 String title, String description, String type, double? value, String? icon
});




}
/// @nodoc
class __$InsightDataCopyWithImpl<$Res>
    implements _$InsightDataCopyWith<$Res> {
  __$InsightDataCopyWithImpl(this._self, this._then);

  final _InsightData _self;
  final $Res Function(_InsightData) _then;

/// Create a copy of InsightData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? type = null,Object? value = freezed,Object? icon = freezed,}) {
  return _then(_InsightData(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AnalysisState {

 List<InsightData> get insights; Map<String, double> get categoryBreakdown; Map<String, double> get monthlyTrend; double get totalSpending; int get transactionCount; double get averageTransaction; bool get isLoading; DateTime? get startDate; DateTime? get endDate; String? get error;// New analytics fields
 Map<String, double> get dailyTotals; Map<String, double> get weeklyTotals; Map<String, double> get topRecipients; Map<String, Map<String, double>> get categoryTrend; AnalyticsView get activeView;
/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisStateCopyWith<AnalysisState> get copyWith => _$AnalysisStateCopyWithImpl<AnalysisState>(this as AnalysisState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisState&&const DeepCollectionEquality().equals(other.insights, insights)&&const DeepCollectionEquality().equals(other.categoryBreakdown, categoryBreakdown)&&const DeepCollectionEquality().equals(other.monthlyTrend, monthlyTrend)&&(identical(other.totalSpending, totalSpending) || other.totalSpending == totalSpending)&&(identical(other.transactionCount, transactionCount) || other.transactionCount == transactionCount)&&(identical(other.averageTransaction, averageTransaction) || other.averageTransaction == averageTransaction)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.dailyTotals, dailyTotals)&&const DeepCollectionEquality().equals(other.weeklyTotals, weeklyTotals)&&const DeepCollectionEquality().equals(other.topRecipients, topRecipients)&&const DeepCollectionEquality().equals(other.categoryTrend, categoryTrend)&&(identical(other.activeView, activeView) || other.activeView == activeView));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(insights),const DeepCollectionEquality().hash(categoryBreakdown),const DeepCollectionEquality().hash(monthlyTrend),totalSpending,transactionCount,averageTransaction,isLoading,startDate,endDate,error,const DeepCollectionEquality().hash(dailyTotals),const DeepCollectionEquality().hash(weeklyTotals),const DeepCollectionEquality().hash(topRecipients),const DeepCollectionEquality().hash(categoryTrend),activeView);

@override
String toString() {
  return 'AnalysisState(insights: $insights, categoryBreakdown: $categoryBreakdown, monthlyTrend: $monthlyTrend, totalSpending: $totalSpending, transactionCount: $transactionCount, averageTransaction: $averageTransaction, isLoading: $isLoading, startDate: $startDate, endDate: $endDate, error: $error, dailyTotals: $dailyTotals, weeklyTotals: $weeklyTotals, topRecipients: $topRecipients, categoryTrend: $categoryTrend, activeView: $activeView)';
}


}

/// @nodoc
abstract mixin class $AnalysisStateCopyWith<$Res>  {
  factory $AnalysisStateCopyWith(AnalysisState value, $Res Function(AnalysisState) _then) = _$AnalysisStateCopyWithImpl;
@useResult
$Res call({
 List<InsightData> insights, Map<String, double> categoryBreakdown, Map<String, double> monthlyTrend, double totalSpending, int transactionCount, double averageTransaction, bool isLoading, DateTime? startDate, DateTime? endDate, String? error, Map<String, double> dailyTotals, Map<String, double> weeklyTotals, Map<String, double> topRecipients, Map<String, Map<String, double>> categoryTrend, AnalyticsView activeView
});




}
/// @nodoc
class _$AnalysisStateCopyWithImpl<$Res>
    implements $AnalysisStateCopyWith<$Res> {
  _$AnalysisStateCopyWithImpl(this._self, this._then);

  final AnalysisState _self;
  final $Res Function(AnalysisState) _then;

/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? insights = null,Object? categoryBreakdown = null,Object? monthlyTrend = null,Object? totalSpending = null,Object? transactionCount = null,Object? averageTransaction = null,Object? isLoading = null,Object? startDate = freezed,Object? endDate = freezed,Object? error = freezed,Object? dailyTotals = null,Object? weeklyTotals = null,Object? topRecipients = null,Object? categoryTrend = null,Object? activeView = null,}) {
  return _then(_self.copyWith(
insights: null == insights ? _self.insights : insights // ignore: cast_nullable_to_non_nullable
as List<InsightData>,categoryBreakdown: null == categoryBreakdown ? _self.categoryBreakdown : categoryBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, double>,monthlyTrend: null == monthlyTrend ? _self.monthlyTrend : monthlyTrend // ignore: cast_nullable_to_non_nullable
as Map<String, double>,totalSpending: null == totalSpending ? _self.totalSpending : totalSpending // ignore: cast_nullable_to_non_nullable
as double,transactionCount: null == transactionCount ? _self.transactionCount : transactionCount // ignore: cast_nullable_to_non_nullable
as int,averageTransaction: null == averageTransaction ? _self.averageTransaction : averageTransaction // ignore: cast_nullable_to_non_nullable
as double,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,dailyTotals: null == dailyTotals ? _self.dailyTotals : dailyTotals // ignore: cast_nullable_to_non_nullable
as Map<String, double>,weeklyTotals: null == weeklyTotals ? _self.weeklyTotals : weeklyTotals // ignore: cast_nullable_to_non_nullable
as Map<String, double>,topRecipients: null == topRecipients ? _self.topRecipients : topRecipients // ignore: cast_nullable_to_non_nullable
as Map<String, double>,categoryTrend: null == categoryTrend ? _self.categoryTrend : categoryTrend // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, double>>,activeView: null == activeView ? _self.activeView : activeView // ignore: cast_nullable_to_non_nullable
as AnalyticsView,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalysisState].
extension AnalysisStatePatterns on AnalysisState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalysisState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalysisState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalysisState value)  $default,){
final _that = this;
switch (_that) {
case _AnalysisState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalysisState value)?  $default,){
final _that = this;
switch (_that) {
case _AnalysisState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<InsightData> insights,  Map<String, double> categoryBreakdown,  Map<String, double> monthlyTrend,  double totalSpending,  int transactionCount,  double averageTransaction,  bool isLoading,  DateTime? startDate,  DateTime? endDate,  String? error,  Map<String, double> dailyTotals,  Map<String, double> weeklyTotals,  Map<String, double> topRecipients,  Map<String, Map<String, double>> categoryTrend,  AnalyticsView activeView)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalysisState() when $default != null:
return $default(_that.insights,_that.categoryBreakdown,_that.monthlyTrend,_that.totalSpending,_that.transactionCount,_that.averageTransaction,_that.isLoading,_that.startDate,_that.endDate,_that.error,_that.dailyTotals,_that.weeklyTotals,_that.topRecipients,_that.categoryTrend,_that.activeView);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<InsightData> insights,  Map<String, double> categoryBreakdown,  Map<String, double> monthlyTrend,  double totalSpending,  int transactionCount,  double averageTransaction,  bool isLoading,  DateTime? startDate,  DateTime? endDate,  String? error,  Map<String, double> dailyTotals,  Map<String, double> weeklyTotals,  Map<String, double> topRecipients,  Map<String, Map<String, double>> categoryTrend,  AnalyticsView activeView)  $default,) {final _that = this;
switch (_that) {
case _AnalysisState():
return $default(_that.insights,_that.categoryBreakdown,_that.monthlyTrend,_that.totalSpending,_that.transactionCount,_that.averageTransaction,_that.isLoading,_that.startDate,_that.endDate,_that.error,_that.dailyTotals,_that.weeklyTotals,_that.topRecipients,_that.categoryTrend,_that.activeView);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<InsightData> insights,  Map<String, double> categoryBreakdown,  Map<String, double> monthlyTrend,  double totalSpending,  int transactionCount,  double averageTransaction,  bool isLoading,  DateTime? startDate,  DateTime? endDate,  String? error,  Map<String, double> dailyTotals,  Map<String, double> weeklyTotals,  Map<String, double> topRecipients,  Map<String, Map<String, double>> categoryTrend,  AnalyticsView activeView)?  $default,) {final _that = this;
switch (_that) {
case _AnalysisState() when $default != null:
return $default(_that.insights,_that.categoryBreakdown,_that.monthlyTrend,_that.totalSpending,_that.transactionCount,_that.averageTransaction,_that.isLoading,_that.startDate,_that.endDate,_that.error,_that.dailyTotals,_that.weeklyTotals,_that.topRecipients,_that.categoryTrend,_that.activeView);case _:
  return null;

}
}

}

/// @nodoc


class _AnalysisState extends AnalysisState {
  const _AnalysisState({final  List<InsightData> insights = const [], final  Map<String, double> categoryBreakdown = const {}, final  Map<String, double> monthlyTrend = const {}, this.totalSpending = 0.0, this.transactionCount = 0, this.averageTransaction = 0.0, this.isLoading = false, this.startDate, this.endDate, this.error, final  Map<String, double> dailyTotals = const {}, final  Map<String, double> weeklyTotals = const {}, final  Map<String, double> topRecipients = const {}, final  Map<String, Map<String, double>> categoryTrend = const {}, this.activeView = AnalyticsView.summary}): _insights = insights,_categoryBreakdown = categoryBreakdown,_monthlyTrend = monthlyTrend,_dailyTotals = dailyTotals,_weeklyTotals = weeklyTotals,_topRecipients = topRecipients,_categoryTrend = categoryTrend,super._();
  

 final  List<InsightData> _insights;
@override@JsonKey() List<InsightData> get insights {
  if (_insights is EqualUnmodifiableListView) return _insights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_insights);
}

 final  Map<String, double> _categoryBreakdown;
@override@JsonKey() Map<String, double> get categoryBreakdown {
  if (_categoryBreakdown is EqualUnmodifiableMapView) return _categoryBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryBreakdown);
}

 final  Map<String, double> _monthlyTrend;
@override@JsonKey() Map<String, double> get monthlyTrend {
  if (_monthlyTrend is EqualUnmodifiableMapView) return _monthlyTrend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_monthlyTrend);
}

@override@JsonKey() final  double totalSpending;
@override@JsonKey() final  int transactionCount;
@override@JsonKey() final  double averageTransaction;
@override@JsonKey() final  bool isLoading;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override final  String? error;
// New analytics fields
 final  Map<String, double> _dailyTotals;
// New analytics fields
@override@JsonKey() Map<String, double> get dailyTotals {
  if (_dailyTotals is EqualUnmodifiableMapView) return _dailyTotals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dailyTotals);
}

 final  Map<String, double> _weeklyTotals;
@override@JsonKey() Map<String, double> get weeklyTotals {
  if (_weeklyTotals is EqualUnmodifiableMapView) return _weeklyTotals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_weeklyTotals);
}

 final  Map<String, double> _topRecipients;
@override@JsonKey() Map<String, double> get topRecipients {
  if (_topRecipients is EqualUnmodifiableMapView) return _topRecipients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_topRecipients);
}

 final  Map<String, Map<String, double>> _categoryTrend;
@override@JsonKey() Map<String, Map<String, double>> get categoryTrend {
  if (_categoryTrend is EqualUnmodifiableMapView) return _categoryTrend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryTrend);
}

@override@JsonKey() final  AnalyticsView activeView;

/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalysisStateCopyWith<_AnalysisState> get copyWith => __$AnalysisStateCopyWithImpl<_AnalysisState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalysisState&&const DeepCollectionEquality().equals(other._insights, _insights)&&const DeepCollectionEquality().equals(other._categoryBreakdown, _categoryBreakdown)&&const DeepCollectionEquality().equals(other._monthlyTrend, _monthlyTrend)&&(identical(other.totalSpending, totalSpending) || other.totalSpending == totalSpending)&&(identical(other.transactionCount, transactionCount) || other.transactionCount == transactionCount)&&(identical(other.averageTransaction, averageTransaction) || other.averageTransaction == averageTransaction)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._dailyTotals, _dailyTotals)&&const DeepCollectionEquality().equals(other._weeklyTotals, _weeklyTotals)&&const DeepCollectionEquality().equals(other._topRecipients, _topRecipients)&&const DeepCollectionEquality().equals(other._categoryTrend, _categoryTrend)&&(identical(other.activeView, activeView) || other.activeView == activeView));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_insights),const DeepCollectionEquality().hash(_categoryBreakdown),const DeepCollectionEquality().hash(_monthlyTrend),totalSpending,transactionCount,averageTransaction,isLoading,startDate,endDate,error,const DeepCollectionEquality().hash(_dailyTotals),const DeepCollectionEquality().hash(_weeklyTotals),const DeepCollectionEquality().hash(_topRecipients),const DeepCollectionEquality().hash(_categoryTrend),activeView);

@override
String toString() {
  return 'AnalysisState(insights: $insights, categoryBreakdown: $categoryBreakdown, monthlyTrend: $monthlyTrend, totalSpending: $totalSpending, transactionCount: $transactionCount, averageTransaction: $averageTransaction, isLoading: $isLoading, startDate: $startDate, endDate: $endDate, error: $error, dailyTotals: $dailyTotals, weeklyTotals: $weeklyTotals, topRecipients: $topRecipients, categoryTrend: $categoryTrend, activeView: $activeView)';
}


}

/// @nodoc
abstract mixin class _$AnalysisStateCopyWith<$Res> implements $AnalysisStateCopyWith<$Res> {
  factory _$AnalysisStateCopyWith(_AnalysisState value, $Res Function(_AnalysisState) _then) = __$AnalysisStateCopyWithImpl;
@override @useResult
$Res call({
 List<InsightData> insights, Map<String, double> categoryBreakdown, Map<String, double> monthlyTrend, double totalSpending, int transactionCount, double averageTransaction, bool isLoading, DateTime? startDate, DateTime? endDate, String? error, Map<String, double> dailyTotals, Map<String, double> weeklyTotals, Map<String, double> topRecipients, Map<String, Map<String, double>> categoryTrend, AnalyticsView activeView
});




}
/// @nodoc
class __$AnalysisStateCopyWithImpl<$Res>
    implements _$AnalysisStateCopyWith<$Res> {
  __$AnalysisStateCopyWithImpl(this._self, this._then);

  final _AnalysisState _self;
  final $Res Function(_AnalysisState) _then;

/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? insights = null,Object? categoryBreakdown = null,Object? monthlyTrend = null,Object? totalSpending = null,Object? transactionCount = null,Object? averageTransaction = null,Object? isLoading = null,Object? startDate = freezed,Object? endDate = freezed,Object? error = freezed,Object? dailyTotals = null,Object? weeklyTotals = null,Object? topRecipients = null,Object? categoryTrend = null,Object? activeView = null,}) {
  return _then(_AnalysisState(
insights: null == insights ? _self._insights : insights // ignore: cast_nullable_to_non_nullable
as List<InsightData>,categoryBreakdown: null == categoryBreakdown ? _self._categoryBreakdown : categoryBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, double>,monthlyTrend: null == monthlyTrend ? _self._monthlyTrend : monthlyTrend // ignore: cast_nullable_to_non_nullable
as Map<String, double>,totalSpending: null == totalSpending ? _self.totalSpending : totalSpending // ignore: cast_nullable_to_non_nullable
as double,transactionCount: null == transactionCount ? _self.transactionCount : transactionCount // ignore: cast_nullable_to_non_nullable
as int,averageTransaction: null == averageTransaction ? _self.averageTransaction : averageTransaction // ignore: cast_nullable_to_non_nullable
as double,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,dailyTotals: null == dailyTotals ? _self._dailyTotals : dailyTotals // ignore: cast_nullable_to_non_nullable
as Map<String, double>,weeklyTotals: null == weeklyTotals ? _self._weeklyTotals : weeklyTotals // ignore: cast_nullable_to_non_nullable
as Map<String, double>,topRecipients: null == topRecipients ? _self._topRecipients : topRecipients // ignore: cast_nullable_to_non_nullable
as Map<String, double>,categoryTrend: null == categoryTrend ? _self._categoryTrend : categoryTrend // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, double>>,activeView: null == activeView ? _self.activeView : activeView // ignore: cast_nullable_to_non_nullable
as AnalyticsView,
  ));
}


}

// dart format on
