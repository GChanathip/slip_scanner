// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'extraction_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExtractionQueueState {

 int get pendingCount; int get processedCount; int get failedCount; int get ragQueueCount; bool get isProcessing; int? get currentSlipId;
/// Create a copy of ExtractionQueueState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExtractionQueueStateCopyWith<ExtractionQueueState> get copyWith => _$ExtractionQueueStateCopyWithImpl<ExtractionQueueState>(this as ExtractionQueueState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExtractionQueueState&&(identical(other.pendingCount, pendingCount) || other.pendingCount == pendingCount)&&(identical(other.processedCount, processedCount) || other.processedCount == processedCount)&&(identical(other.failedCount, failedCount) || other.failedCount == failedCount)&&(identical(other.ragQueueCount, ragQueueCount) || other.ragQueueCount == ragQueueCount)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing)&&(identical(other.currentSlipId, currentSlipId) || other.currentSlipId == currentSlipId));
}


@override
int get hashCode => Object.hash(runtimeType,pendingCount,processedCount,failedCount,ragQueueCount,isProcessing,currentSlipId);

@override
String toString() {
  return 'ExtractionQueueState(pendingCount: $pendingCount, processedCount: $processedCount, failedCount: $failedCount, ragQueueCount: $ragQueueCount, isProcessing: $isProcessing, currentSlipId: $currentSlipId)';
}


}

/// @nodoc
abstract mixin class $ExtractionQueueStateCopyWith<$Res>  {
  factory $ExtractionQueueStateCopyWith(ExtractionQueueState value, $Res Function(ExtractionQueueState) _then) = _$ExtractionQueueStateCopyWithImpl;
@useResult
$Res call({
 int pendingCount, int processedCount, int failedCount, int ragQueueCount, bool isProcessing, int? currentSlipId
});




}
/// @nodoc
class _$ExtractionQueueStateCopyWithImpl<$Res>
    implements $ExtractionQueueStateCopyWith<$Res> {
  _$ExtractionQueueStateCopyWithImpl(this._self, this._then);

  final ExtractionQueueState _self;
  final $Res Function(ExtractionQueueState) _then;

/// Create a copy of ExtractionQueueState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pendingCount = null,Object? processedCount = null,Object? failedCount = null,Object? ragQueueCount = null,Object? isProcessing = null,Object? currentSlipId = freezed,}) {
  return _then(_self.copyWith(
pendingCount: null == pendingCount ? _self.pendingCount : pendingCount // ignore: cast_nullable_to_non_nullable
as int,processedCount: null == processedCount ? _self.processedCount : processedCount // ignore: cast_nullable_to_non_nullable
as int,failedCount: null == failedCount ? _self.failedCount : failedCount // ignore: cast_nullable_to_non_nullable
as int,ragQueueCount: null == ragQueueCount ? _self.ragQueueCount : ragQueueCount // ignore: cast_nullable_to_non_nullable
as int,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,currentSlipId: freezed == currentSlipId ? _self.currentSlipId : currentSlipId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExtractionQueueState].
extension ExtractionQueueStatePatterns on ExtractionQueueState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExtractionQueueState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExtractionQueueState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExtractionQueueState value)  $default,){
final _that = this;
switch (_that) {
case _ExtractionQueueState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExtractionQueueState value)?  $default,){
final _that = this;
switch (_that) {
case _ExtractionQueueState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pendingCount,  int processedCount,  int failedCount,  int ragQueueCount,  bool isProcessing,  int? currentSlipId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExtractionQueueState() when $default != null:
return $default(_that.pendingCount,_that.processedCount,_that.failedCount,_that.ragQueueCount,_that.isProcessing,_that.currentSlipId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pendingCount,  int processedCount,  int failedCount,  int ragQueueCount,  bool isProcessing,  int? currentSlipId)  $default,) {final _that = this;
switch (_that) {
case _ExtractionQueueState():
return $default(_that.pendingCount,_that.processedCount,_that.failedCount,_that.ragQueueCount,_that.isProcessing,_that.currentSlipId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pendingCount,  int processedCount,  int failedCount,  int ragQueueCount,  bool isProcessing,  int? currentSlipId)?  $default,) {final _that = this;
switch (_that) {
case _ExtractionQueueState() when $default != null:
return $default(_that.pendingCount,_that.processedCount,_that.failedCount,_that.ragQueueCount,_that.isProcessing,_that.currentSlipId);case _:
  return null;

}
}

}

/// @nodoc


class _ExtractionQueueState extends ExtractionQueueState {
  const _ExtractionQueueState({this.pendingCount = 0, this.processedCount = 0, this.failedCount = 0, this.ragQueueCount = 0, this.isProcessing = false, this.currentSlipId}): super._();
  

@override@JsonKey() final  int pendingCount;
@override@JsonKey() final  int processedCount;
@override@JsonKey() final  int failedCount;
@override@JsonKey() final  int ragQueueCount;
@override@JsonKey() final  bool isProcessing;
@override final  int? currentSlipId;

/// Create a copy of ExtractionQueueState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExtractionQueueStateCopyWith<_ExtractionQueueState> get copyWith => __$ExtractionQueueStateCopyWithImpl<_ExtractionQueueState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExtractionQueueState&&(identical(other.pendingCount, pendingCount) || other.pendingCount == pendingCount)&&(identical(other.processedCount, processedCount) || other.processedCount == processedCount)&&(identical(other.failedCount, failedCount) || other.failedCount == failedCount)&&(identical(other.ragQueueCount, ragQueueCount) || other.ragQueueCount == ragQueueCount)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing)&&(identical(other.currentSlipId, currentSlipId) || other.currentSlipId == currentSlipId));
}


@override
int get hashCode => Object.hash(runtimeType,pendingCount,processedCount,failedCount,ragQueueCount,isProcessing,currentSlipId);

@override
String toString() {
  return 'ExtractionQueueState(pendingCount: $pendingCount, processedCount: $processedCount, failedCount: $failedCount, ragQueueCount: $ragQueueCount, isProcessing: $isProcessing, currentSlipId: $currentSlipId)';
}


}

/// @nodoc
abstract mixin class _$ExtractionQueueStateCopyWith<$Res> implements $ExtractionQueueStateCopyWith<$Res> {
  factory _$ExtractionQueueStateCopyWith(_ExtractionQueueState value, $Res Function(_ExtractionQueueState) _then) = __$ExtractionQueueStateCopyWithImpl;
@override @useResult
$Res call({
 int pendingCount, int processedCount, int failedCount, int ragQueueCount, bool isProcessing, int? currentSlipId
});




}
/// @nodoc
class __$ExtractionQueueStateCopyWithImpl<$Res>
    implements _$ExtractionQueueStateCopyWith<$Res> {
  __$ExtractionQueueStateCopyWithImpl(this._self, this._then);

  final _ExtractionQueueState _self;
  final $Res Function(_ExtractionQueueState) _then;

/// Create a copy of ExtractionQueueState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pendingCount = null,Object? processedCount = null,Object? failedCount = null,Object? ragQueueCount = null,Object? isProcessing = null,Object? currentSlipId = freezed,}) {
  return _then(_ExtractionQueueState(
pendingCount: null == pendingCount ? _self.pendingCount : pendingCount // ignore: cast_nullable_to_non_nullable
as int,processedCount: null == processedCount ? _self.processedCount : processedCount // ignore: cast_nullable_to_non_nullable
as int,failedCount: null == failedCount ? _self.failedCount : failedCount // ignore: cast_nullable_to_non_nullable
as int,ragQueueCount: null == ragQueueCount ? _self.ragQueueCount : ragQueueCount // ignore: cast_nullable_to_non_nullable
as int,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,currentSlipId: freezed == currentSlipId ? _self.currentSlipId : currentSlipId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
