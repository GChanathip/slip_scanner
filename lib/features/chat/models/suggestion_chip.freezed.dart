// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'suggestion_chip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SuggestionChip {

 String get label; String get query; String? get icon;
/// Create a copy of SuggestionChip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SuggestionChipCopyWith<SuggestionChip> get copyWith => _$SuggestionChipCopyWithImpl<SuggestionChip>(this as SuggestionChip, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SuggestionChip&&(identical(other.label, label) || other.label == label)&&(identical(other.query, query) || other.query == query)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,label,query,icon);

@override
String toString() {
  return 'SuggestionChip(label: $label, query: $query, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $SuggestionChipCopyWith<$Res>  {
  factory $SuggestionChipCopyWith(SuggestionChip value, $Res Function(SuggestionChip) _then) = _$SuggestionChipCopyWithImpl;
@useResult
$Res call({
 String label, String query, String? icon
});




}
/// @nodoc
class _$SuggestionChipCopyWithImpl<$Res>
    implements $SuggestionChipCopyWith<$Res> {
  _$SuggestionChipCopyWithImpl(this._self, this._then);

  final SuggestionChip _self;
  final $Res Function(SuggestionChip) _then;

/// Create a copy of SuggestionChip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? query = null,Object? icon = freezed,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SuggestionChip].
extension SuggestionChipPatterns on SuggestionChip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SuggestionChip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SuggestionChip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SuggestionChip value)  $default,){
final _that = this;
switch (_that) {
case _SuggestionChip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SuggestionChip value)?  $default,){
final _that = this;
switch (_that) {
case _SuggestionChip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String query,  String? icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SuggestionChip() when $default != null:
return $default(_that.label,_that.query,_that.icon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String query,  String? icon)  $default,) {final _that = this;
switch (_that) {
case _SuggestionChip():
return $default(_that.label,_that.query,_that.icon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String query,  String? icon)?  $default,) {final _that = this;
switch (_that) {
case _SuggestionChip() when $default != null:
return $default(_that.label,_that.query,_that.icon);case _:
  return null;

}
}

}

/// @nodoc


class _SuggestionChip implements SuggestionChip {
  const _SuggestionChip({required this.label, required this.query, this.icon});
  

@override final  String label;
@override final  String query;
@override final  String? icon;

/// Create a copy of SuggestionChip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuggestionChipCopyWith<_SuggestionChip> get copyWith => __$SuggestionChipCopyWithImpl<_SuggestionChip>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SuggestionChip&&(identical(other.label, label) || other.label == label)&&(identical(other.query, query) || other.query == query)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,label,query,icon);

@override
String toString() {
  return 'SuggestionChip(label: $label, query: $query, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$SuggestionChipCopyWith<$Res> implements $SuggestionChipCopyWith<$Res> {
  factory _$SuggestionChipCopyWith(_SuggestionChip value, $Res Function(_SuggestionChip) _then) = __$SuggestionChipCopyWithImpl;
@override @useResult
$Res call({
 String label, String query, String? icon
});




}
/// @nodoc
class __$SuggestionChipCopyWithImpl<$Res>
    implements _$SuggestionChipCopyWith<$Res> {
  __$SuggestionChipCopyWithImpl(this._self, this._then);

  final _SuggestionChip _self;
  final $Res Function(_SuggestionChip) _then;

/// Create a copy of SuggestionChip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? query = null,Object? icon = freezed,}) {
  return _then(_SuggestionChip(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
