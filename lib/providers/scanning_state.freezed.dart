// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scanning_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScanningState {

 bool get isScanning; int get totalPhotos; int get processedPhotos; int get slipsFound; bool get isComplete; String? get error;
/// Create a copy of ScanningState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanningStateCopyWith<ScanningState> get copyWith => _$ScanningStateCopyWithImpl<ScanningState>(this as ScanningState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanningState&&(identical(other.isScanning, isScanning) || other.isScanning == isScanning)&&(identical(other.totalPhotos, totalPhotos) || other.totalPhotos == totalPhotos)&&(identical(other.processedPhotos, processedPhotos) || other.processedPhotos == processedPhotos)&&(identical(other.slipsFound, slipsFound) || other.slipsFound == slipsFound)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,isScanning,totalPhotos,processedPhotos,slipsFound,isComplete,error);

@override
String toString() {
  return 'ScanningState(isScanning: $isScanning, totalPhotos: $totalPhotos, processedPhotos: $processedPhotos, slipsFound: $slipsFound, isComplete: $isComplete, error: $error)';
}


}

/// @nodoc
abstract mixin class $ScanningStateCopyWith<$Res>  {
  factory $ScanningStateCopyWith(ScanningState value, $Res Function(ScanningState) _then) = _$ScanningStateCopyWithImpl;
@useResult
$Res call({
 bool isScanning, int totalPhotos, int processedPhotos, int slipsFound, bool isComplete, String? error
});




}
/// @nodoc
class _$ScanningStateCopyWithImpl<$Res>
    implements $ScanningStateCopyWith<$Res> {
  _$ScanningStateCopyWithImpl(this._self, this._then);

  final ScanningState _self;
  final $Res Function(ScanningState) _then;

/// Create a copy of ScanningState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isScanning = null,Object? totalPhotos = null,Object? processedPhotos = null,Object? slipsFound = null,Object? isComplete = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
isScanning: null == isScanning ? _self.isScanning : isScanning // ignore: cast_nullable_to_non_nullable
as bool,totalPhotos: null == totalPhotos ? _self.totalPhotos : totalPhotos // ignore: cast_nullable_to_non_nullable
as int,processedPhotos: null == processedPhotos ? _self.processedPhotos : processedPhotos // ignore: cast_nullable_to_non_nullable
as int,slipsFound: null == slipsFound ? _self.slipsFound : slipsFound // ignore: cast_nullable_to_non_nullable
as int,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanningState].
extension ScanningStatePatterns on ScanningState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanningState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanningState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanningState value)  $default,){
final _that = this;
switch (_that) {
case _ScanningState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanningState value)?  $default,){
final _that = this;
switch (_that) {
case _ScanningState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isScanning,  int totalPhotos,  int processedPhotos,  int slipsFound,  bool isComplete,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanningState() when $default != null:
return $default(_that.isScanning,_that.totalPhotos,_that.processedPhotos,_that.slipsFound,_that.isComplete,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isScanning,  int totalPhotos,  int processedPhotos,  int slipsFound,  bool isComplete,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ScanningState():
return $default(_that.isScanning,_that.totalPhotos,_that.processedPhotos,_that.slipsFound,_that.isComplete,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isScanning,  int totalPhotos,  int processedPhotos,  int slipsFound,  bool isComplete,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ScanningState() when $default != null:
return $default(_that.isScanning,_that.totalPhotos,_that.processedPhotos,_that.slipsFound,_that.isComplete,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ScanningState extends ScanningState {
  const _ScanningState({this.isScanning = false, this.totalPhotos = 0, this.processedPhotos = 0, this.slipsFound = 0, this.isComplete = false, this.error}): super._();


@override@JsonKey() final  bool isScanning;
@override@JsonKey() final  int totalPhotos;
@override@JsonKey() final  int processedPhotos;
@override@JsonKey() final  int slipsFound;
@override@JsonKey() final  bool isComplete;
@override final  String? error;

/// Create a copy of ScanningState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanningStateCopyWith<_ScanningState> get copyWith => __$ScanningStateCopyWithImpl<_ScanningState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanningState&&(identical(other.isScanning, isScanning) || other.isScanning == isScanning)&&(identical(other.totalPhotos, totalPhotos) || other.totalPhotos == totalPhotos)&&(identical(other.processedPhotos, processedPhotos) || other.processedPhotos == processedPhotos)&&(identical(other.slipsFound, slipsFound) || other.slipsFound == slipsFound)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,isScanning,totalPhotos,processedPhotos,slipsFound,isComplete,error);

@override
String toString() {
  return 'ScanningState(isScanning: $isScanning, totalPhotos: $totalPhotos, processedPhotos: $processedPhotos, slipsFound: $slipsFound, isComplete: $isComplete, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ScanningStateCopyWith<$Res> implements $ScanningStateCopyWith<$Res> {
  factory _$ScanningStateCopyWith(_ScanningState value, $Res Function(_ScanningState) _then) = __$ScanningStateCopyWithImpl;
@override @useResult
$Res call({
 bool isScanning, int totalPhotos, int processedPhotos, int slipsFound, bool isComplete, String? error
});




}
/// @nodoc
class __$ScanningStateCopyWithImpl<$Res>
    implements _$ScanningStateCopyWith<$Res> {
  __$ScanningStateCopyWithImpl(this._self, this._then);

  final _ScanningState _self;
  final $Res Function(_ScanningState) _then;

/// Create a copy of ScanningState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isScanning = null,Object? totalPhotos = null,Object? processedPhotos = null,Object? slipsFound = null,Object? isComplete = null,Object? error = freezed,}) {
  return _then(_ScanningState(
isScanning: null == isScanning ? _self.isScanning : isScanning // ignore: cast_nullable_to_non_nullable
as bool,totalPhotos: null == totalPhotos ? _self.totalPhotos : totalPhotos // ignore: cast_nullable_to_non_nullable
as int,processedPhotos: null == processedPhotos ? _self.processedPhotos : processedPhotos // ignore: cast_nullable_to_non_nullable
as int,slipsFound: null == slipsFound ? _self.slipsFound : slipsFound // ignore: cast_nullable_to_non_nullable
as int,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
