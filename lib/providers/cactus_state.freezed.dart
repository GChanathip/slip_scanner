// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cactus_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CactusState {

 bool get isDownloading; bool get isInitializing; bool get isModelLoaded; double get downloadProgress; String get downloadStatus; String get selectedModel; String? get error;
/// Create a copy of CactusState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CactusStateCopyWith<CactusState> get copyWith => _$CactusStateCopyWithImpl<CactusState>(this as CactusState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CactusState&&(identical(other.isDownloading, isDownloading) || other.isDownloading == isDownloading)&&(identical(other.isInitializing, isInitializing) || other.isInitializing == isInitializing)&&(identical(other.isModelLoaded, isModelLoaded) || other.isModelLoaded == isModelLoaded)&&(identical(other.downloadProgress, downloadProgress) || other.downloadProgress == downloadProgress)&&(identical(other.downloadStatus, downloadStatus) || other.downloadStatus == downloadStatus)&&(identical(other.selectedModel, selectedModel) || other.selectedModel == selectedModel)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,isDownloading,isInitializing,isModelLoaded,downloadProgress,downloadStatus,selectedModel,error);

@override
String toString() {
  return 'CactusState(isDownloading: $isDownloading, isInitializing: $isInitializing, isModelLoaded: $isModelLoaded, downloadProgress: $downloadProgress, downloadStatus: $downloadStatus, selectedModel: $selectedModel, error: $error)';
}


}

/// @nodoc
abstract mixin class $CactusStateCopyWith<$Res>  {
  factory $CactusStateCopyWith(CactusState value, $Res Function(CactusState) _then) = _$CactusStateCopyWithImpl;
@useResult
$Res call({
 bool isDownloading, bool isInitializing, bool isModelLoaded, double downloadProgress, String downloadStatus, String selectedModel, String? error
});




}
/// @nodoc
class _$CactusStateCopyWithImpl<$Res>
    implements $CactusStateCopyWith<$Res> {
  _$CactusStateCopyWithImpl(this._self, this._then);

  final CactusState _self;
  final $Res Function(CactusState) _then;

/// Create a copy of CactusState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isDownloading = null,Object? isInitializing = null,Object? isModelLoaded = null,Object? downloadProgress = null,Object? downloadStatus = null,Object? selectedModel = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
isDownloading: null == isDownloading ? _self.isDownloading : isDownloading // ignore: cast_nullable_to_non_nullable
as bool,isInitializing: null == isInitializing ? _self.isInitializing : isInitializing // ignore: cast_nullable_to_non_nullable
as bool,isModelLoaded: null == isModelLoaded ? _self.isModelLoaded : isModelLoaded // ignore: cast_nullable_to_non_nullable
as bool,downloadProgress: null == downloadProgress ? _self.downloadProgress : downloadProgress // ignore: cast_nullable_to_non_nullable
as double,downloadStatus: null == downloadStatus ? _self.downloadStatus : downloadStatus // ignore: cast_nullable_to_non_nullable
as String,selectedModel: null == selectedModel ? _self.selectedModel : selectedModel // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CactusState].
extension CactusStatePatterns on CactusState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CactusState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CactusState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CactusState value)  $default,){
final _that = this;
switch (_that) {
case _CactusState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CactusState value)?  $default,){
final _that = this;
switch (_that) {
case _CactusState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isDownloading,  bool isInitializing,  bool isModelLoaded,  double downloadProgress,  String downloadStatus,  String selectedModel,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CactusState() when $default != null:
return $default(_that.isDownloading,_that.isInitializing,_that.isModelLoaded,_that.downloadProgress,_that.downloadStatus,_that.selectedModel,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isDownloading,  bool isInitializing,  bool isModelLoaded,  double downloadProgress,  String downloadStatus,  String selectedModel,  String? error)  $default,) {final _that = this;
switch (_that) {
case _CactusState():
return $default(_that.isDownloading,_that.isInitializing,_that.isModelLoaded,_that.downloadProgress,_that.downloadStatus,_that.selectedModel,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isDownloading,  bool isInitializing,  bool isModelLoaded,  double downloadProgress,  String downloadStatus,  String selectedModel,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _CactusState() when $default != null:
return $default(_that.isDownloading,_that.isInitializing,_that.isModelLoaded,_that.downloadProgress,_that.downloadStatus,_that.selectedModel,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _CactusState extends CactusState {
  const _CactusState({this.isDownloading = false, this.isInitializing = false, this.isModelLoaded = false, this.downloadProgress = 0.0, this.downloadStatus = '', this.selectedModel = 'qwen3-0.6', this.error}): super._();
  

@override@JsonKey() final  bool isDownloading;
@override@JsonKey() final  bool isInitializing;
@override@JsonKey() final  bool isModelLoaded;
@override@JsonKey() final  double downloadProgress;
@override@JsonKey() final  String downloadStatus;
@override@JsonKey() final  String selectedModel;
@override final  String? error;

/// Create a copy of CactusState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CactusStateCopyWith<_CactusState> get copyWith => __$CactusStateCopyWithImpl<_CactusState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CactusState&&(identical(other.isDownloading, isDownloading) || other.isDownloading == isDownloading)&&(identical(other.isInitializing, isInitializing) || other.isInitializing == isInitializing)&&(identical(other.isModelLoaded, isModelLoaded) || other.isModelLoaded == isModelLoaded)&&(identical(other.downloadProgress, downloadProgress) || other.downloadProgress == downloadProgress)&&(identical(other.downloadStatus, downloadStatus) || other.downloadStatus == downloadStatus)&&(identical(other.selectedModel, selectedModel) || other.selectedModel == selectedModel)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,isDownloading,isInitializing,isModelLoaded,downloadProgress,downloadStatus,selectedModel,error);

@override
String toString() {
  return 'CactusState(isDownloading: $isDownloading, isInitializing: $isInitializing, isModelLoaded: $isModelLoaded, downloadProgress: $downloadProgress, downloadStatus: $downloadStatus, selectedModel: $selectedModel, error: $error)';
}


}

/// @nodoc
abstract mixin class _$CactusStateCopyWith<$Res> implements $CactusStateCopyWith<$Res> {
  factory _$CactusStateCopyWith(_CactusState value, $Res Function(_CactusState) _then) = __$CactusStateCopyWithImpl;
@override @useResult
$Res call({
 bool isDownloading, bool isInitializing, bool isModelLoaded, double downloadProgress, String downloadStatus, String selectedModel, String? error
});




}
/// @nodoc
class __$CactusStateCopyWithImpl<$Res>
    implements _$CactusStateCopyWith<$Res> {
  __$CactusStateCopyWithImpl(this._self, this._then);

  final _CactusState _self;
  final $Res Function(_CactusState) _then;

/// Create a copy of CactusState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isDownloading = null,Object? isInitializing = null,Object? isModelLoaded = null,Object? downloadProgress = null,Object? downloadStatus = null,Object? selectedModel = null,Object? error = freezed,}) {
  return _then(_CactusState(
isDownloading: null == isDownloading ? _self.isDownloading : isDownloading // ignore: cast_nullable_to_non_nullable
as bool,isInitializing: null == isInitializing ? _self.isInitializing : isInitializing // ignore: cast_nullable_to_non_nullable
as bool,isModelLoaded: null == isModelLoaded ? _self.isModelLoaded : isModelLoaded // ignore: cast_nullable_to_non_nullable
as bool,downloadProgress: null == downloadProgress ? _self.downloadProgress : downloadProgress // ignore: cast_nullable_to_non_nullable
as double,downloadStatus: null == downloadStatus ? _self.downloadStatus : downloadStatus // ignore: cast_nullable_to_non_nullable
as String,selectedModel: null == selectedModel ? _self.selectedModel : selectedModel // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
