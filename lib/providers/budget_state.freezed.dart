// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BudgetAlert {

 String get label;// 'Overall' or category name
 double get spent; double get budget; double get percentage; BudgetAlertLevel get level;
/// Create a copy of BudgetAlert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetAlertCopyWith<BudgetAlert> get copyWith => _$BudgetAlertCopyWithImpl<BudgetAlert>(this as BudgetAlert, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetAlert&&(identical(other.label, label) || other.label == label)&&(identical(other.spent, spent) || other.spent == spent)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.percentage, percentage) || other.percentage == percentage)&&(identical(other.level, level) || other.level == level));
}


@override
int get hashCode => Object.hash(runtimeType,label,spent,budget,percentage,level);

@override
String toString() {
  return 'BudgetAlert(label: $label, spent: $spent, budget: $budget, percentage: $percentage, level: $level)';
}


}

/// @nodoc
abstract mixin class $BudgetAlertCopyWith<$Res>  {
  factory $BudgetAlertCopyWith(BudgetAlert value, $Res Function(BudgetAlert) _then) = _$BudgetAlertCopyWithImpl;
@useResult
$Res call({
 String label, double spent, double budget, double percentage, BudgetAlertLevel level
});




}
/// @nodoc
class _$BudgetAlertCopyWithImpl<$Res>
    implements $BudgetAlertCopyWith<$Res> {
  _$BudgetAlertCopyWithImpl(this._self, this._then);

  final BudgetAlert _self;
  final $Res Function(BudgetAlert) _then;

/// Create a copy of BudgetAlert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? spent = null,Object? budget = null,Object? percentage = null,Object? level = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as double,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as double,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as BudgetAlertLevel,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetAlert].
extension BudgetAlertPatterns on BudgetAlert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetAlert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetAlert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetAlert value)  $default,){
final _that = this;
switch (_that) {
case _BudgetAlert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetAlert value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetAlert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  double spent,  double budget,  double percentage,  BudgetAlertLevel level)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetAlert() when $default != null:
return $default(_that.label,_that.spent,_that.budget,_that.percentage,_that.level);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  double spent,  double budget,  double percentage,  BudgetAlertLevel level)  $default,) {final _that = this;
switch (_that) {
case _BudgetAlert():
return $default(_that.label,_that.spent,_that.budget,_that.percentage,_that.level);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  double spent,  double budget,  double percentage,  BudgetAlertLevel level)?  $default,) {final _that = this;
switch (_that) {
case _BudgetAlert() when $default != null:
return $default(_that.label,_that.spent,_that.budget,_that.percentage,_that.level);case _:
  return null;

}
}

}

/// @nodoc


class _BudgetAlert implements BudgetAlert {
  const _BudgetAlert({required this.label, required this.spent, required this.budget, required this.percentage, required this.level});
  

@override final  String label;
// 'Overall' or category name
@override final  double spent;
@override final  double budget;
@override final  double percentage;
@override final  BudgetAlertLevel level;

/// Create a copy of BudgetAlert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetAlertCopyWith<_BudgetAlert> get copyWith => __$BudgetAlertCopyWithImpl<_BudgetAlert>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetAlert&&(identical(other.label, label) || other.label == label)&&(identical(other.spent, spent) || other.spent == spent)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.percentage, percentage) || other.percentage == percentage)&&(identical(other.level, level) || other.level == level));
}


@override
int get hashCode => Object.hash(runtimeType,label,spent,budget,percentage,level);

@override
String toString() {
  return 'BudgetAlert(label: $label, spent: $spent, budget: $budget, percentage: $percentage, level: $level)';
}


}

/// @nodoc
abstract mixin class _$BudgetAlertCopyWith<$Res> implements $BudgetAlertCopyWith<$Res> {
  factory _$BudgetAlertCopyWith(_BudgetAlert value, $Res Function(_BudgetAlert) _then) = __$BudgetAlertCopyWithImpl;
@override @useResult
$Res call({
 String label, double spent, double budget, double percentage, BudgetAlertLevel level
});




}
/// @nodoc
class __$BudgetAlertCopyWithImpl<$Res>
    implements _$BudgetAlertCopyWith<$Res> {
  __$BudgetAlertCopyWithImpl(this._self, this._then);

  final _BudgetAlert _self;
  final $Res Function(_BudgetAlert) _then;

/// Create a copy of BudgetAlert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? spent = null,Object? budget = null,Object? percentage = null,Object? level = null,}) {
  return _then(_BudgetAlert(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as double,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as double,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as BudgetAlertLevel,
  ));
}


}

/// @nodoc
mixin _$BudgetState {

 double get overallBudget; Map<String, double> get categoryBudgets; double get currentMonthSpent; Map<String, double> get currentMonthByCategory; List<BudgetAlert> get alerts; bool get isLoading;
/// Create a copy of BudgetState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetStateCopyWith<BudgetState> get copyWith => _$BudgetStateCopyWithImpl<BudgetState>(this as BudgetState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetState&&(identical(other.overallBudget, overallBudget) || other.overallBudget == overallBudget)&&const DeepCollectionEquality().equals(other.categoryBudgets, categoryBudgets)&&(identical(other.currentMonthSpent, currentMonthSpent) || other.currentMonthSpent == currentMonthSpent)&&const DeepCollectionEquality().equals(other.currentMonthByCategory, currentMonthByCategory)&&const DeepCollectionEquality().equals(other.alerts, alerts)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,overallBudget,const DeepCollectionEquality().hash(categoryBudgets),currentMonthSpent,const DeepCollectionEquality().hash(currentMonthByCategory),const DeepCollectionEquality().hash(alerts),isLoading);

@override
String toString() {
  return 'BudgetState(overallBudget: $overallBudget, categoryBudgets: $categoryBudgets, currentMonthSpent: $currentMonthSpent, currentMonthByCategory: $currentMonthByCategory, alerts: $alerts, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $BudgetStateCopyWith<$Res>  {
  factory $BudgetStateCopyWith(BudgetState value, $Res Function(BudgetState) _then) = _$BudgetStateCopyWithImpl;
@useResult
$Res call({
 double overallBudget, Map<String, double> categoryBudgets, double currentMonthSpent, Map<String, double> currentMonthByCategory, List<BudgetAlert> alerts, bool isLoading
});




}
/// @nodoc
class _$BudgetStateCopyWithImpl<$Res>
    implements $BudgetStateCopyWith<$Res> {
  _$BudgetStateCopyWithImpl(this._self, this._then);

  final BudgetState _self;
  final $Res Function(BudgetState) _then;

/// Create a copy of BudgetState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overallBudget = null,Object? categoryBudgets = null,Object? currentMonthSpent = null,Object? currentMonthByCategory = null,Object? alerts = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
overallBudget: null == overallBudget ? _self.overallBudget : overallBudget // ignore: cast_nullable_to_non_nullable
as double,categoryBudgets: null == categoryBudgets ? _self.categoryBudgets : categoryBudgets // ignore: cast_nullable_to_non_nullable
as Map<String, double>,currentMonthSpent: null == currentMonthSpent ? _self.currentMonthSpent : currentMonthSpent // ignore: cast_nullable_to_non_nullable
as double,currentMonthByCategory: null == currentMonthByCategory ? _self.currentMonthByCategory : currentMonthByCategory // ignore: cast_nullable_to_non_nullable
as Map<String, double>,alerts: null == alerts ? _self.alerts : alerts // ignore: cast_nullable_to_non_nullable
as List<BudgetAlert>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetState].
extension BudgetStatePatterns on BudgetState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetState value)  $default,){
final _that = this;
switch (_that) {
case _BudgetState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetState value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double overallBudget,  Map<String, double> categoryBudgets,  double currentMonthSpent,  Map<String, double> currentMonthByCategory,  List<BudgetAlert> alerts,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetState() when $default != null:
return $default(_that.overallBudget,_that.categoryBudgets,_that.currentMonthSpent,_that.currentMonthByCategory,_that.alerts,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double overallBudget,  Map<String, double> categoryBudgets,  double currentMonthSpent,  Map<String, double> currentMonthByCategory,  List<BudgetAlert> alerts,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _BudgetState():
return $default(_that.overallBudget,_that.categoryBudgets,_that.currentMonthSpent,_that.currentMonthByCategory,_that.alerts,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double overallBudget,  Map<String, double> categoryBudgets,  double currentMonthSpent,  Map<String, double> currentMonthByCategory,  List<BudgetAlert> alerts,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _BudgetState() when $default != null:
return $default(_that.overallBudget,_that.categoryBudgets,_that.currentMonthSpent,_that.currentMonthByCategory,_that.alerts,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _BudgetState extends BudgetState {
  const _BudgetState({this.overallBudget = 0, final  Map<String, double> categoryBudgets = const {}, this.currentMonthSpent = 0, final  Map<String, double> currentMonthByCategory = const {}, final  List<BudgetAlert> alerts = const [], this.isLoading = false}): _categoryBudgets = categoryBudgets,_currentMonthByCategory = currentMonthByCategory,_alerts = alerts,super._();
  

@override@JsonKey() final  double overallBudget;
 final  Map<String, double> _categoryBudgets;
@override@JsonKey() Map<String, double> get categoryBudgets {
  if (_categoryBudgets is EqualUnmodifiableMapView) return _categoryBudgets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryBudgets);
}

@override@JsonKey() final  double currentMonthSpent;
 final  Map<String, double> _currentMonthByCategory;
@override@JsonKey() Map<String, double> get currentMonthByCategory {
  if (_currentMonthByCategory is EqualUnmodifiableMapView) return _currentMonthByCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_currentMonthByCategory);
}

 final  List<BudgetAlert> _alerts;
@override@JsonKey() List<BudgetAlert> get alerts {
  if (_alerts is EqualUnmodifiableListView) return _alerts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alerts);
}

@override@JsonKey() final  bool isLoading;

/// Create a copy of BudgetState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetStateCopyWith<_BudgetState> get copyWith => __$BudgetStateCopyWithImpl<_BudgetState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetState&&(identical(other.overallBudget, overallBudget) || other.overallBudget == overallBudget)&&const DeepCollectionEquality().equals(other._categoryBudgets, _categoryBudgets)&&(identical(other.currentMonthSpent, currentMonthSpent) || other.currentMonthSpent == currentMonthSpent)&&const DeepCollectionEquality().equals(other._currentMonthByCategory, _currentMonthByCategory)&&const DeepCollectionEquality().equals(other._alerts, _alerts)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,overallBudget,const DeepCollectionEquality().hash(_categoryBudgets),currentMonthSpent,const DeepCollectionEquality().hash(_currentMonthByCategory),const DeepCollectionEquality().hash(_alerts),isLoading);

@override
String toString() {
  return 'BudgetState(overallBudget: $overallBudget, categoryBudgets: $categoryBudgets, currentMonthSpent: $currentMonthSpent, currentMonthByCategory: $currentMonthByCategory, alerts: $alerts, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$BudgetStateCopyWith<$Res> implements $BudgetStateCopyWith<$Res> {
  factory _$BudgetStateCopyWith(_BudgetState value, $Res Function(_BudgetState) _then) = __$BudgetStateCopyWithImpl;
@override @useResult
$Res call({
 double overallBudget, Map<String, double> categoryBudgets, double currentMonthSpent, Map<String, double> currentMonthByCategory, List<BudgetAlert> alerts, bool isLoading
});




}
/// @nodoc
class __$BudgetStateCopyWithImpl<$Res>
    implements _$BudgetStateCopyWith<$Res> {
  __$BudgetStateCopyWithImpl(this._self, this._then);

  final _BudgetState _self;
  final $Res Function(_BudgetState) _then;

/// Create a copy of BudgetState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overallBudget = null,Object? categoryBudgets = null,Object? currentMonthSpent = null,Object? currentMonthByCategory = null,Object? alerts = null,Object? isLoading = null,}) {
  return _then(_BudgetState(
overallBudget: null == overallBudget ? _self.overallBudget : overallBudget // ignore: cast_nullable_to_non_nullable
as double,categoryBudgets: null == categoryBudgets ? _self._categoryBudgets : categoryBudgets // ignore: cast_nullable_to_non_nullable
as Map<String, double>,currentMonthSpent: null == currentMonthSpent ? _self.currentMonthSpent : currentMonthSpent // ignore: cast_nullable_to_non_nullable
as double,currentMonthByCategory: null == currentMonthByCategory ? _self._currentMonthByCategory : currentMonthByCategory // ignore: cast_nullable_to_non_nullable
as Map<String, double>,alerts: null == alerts ? _self._alerts : alerts // ignore: cast_nullable_to_non_nullable
as List<BudgetAlert>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
