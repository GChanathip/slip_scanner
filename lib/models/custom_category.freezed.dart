// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomCategory {

 int? get id; String get name; String get icon; String get color; String get createdAt;
/// Create a copy of CustomCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomCategoryCopyWith<CustomCategory> get copyWith => _$CustomCategoryCopyWithImpl<CustomCategory>(this as CustomCategory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,createdAt);

@override
String toString() {
  return 'CustomCategory(id: $id, name: $name, icon: $icon, color: $color, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CustomCategoryCopyWith<$Res>  {
  factory $CustomCategoryCopyWith(CustomCategory value, $Res Function(CustomCategory) _then) = _$CustomCategoryCopyWithImpl;
@useResult
$Res call({
 int? id, String name, String icon, String color, String createdAt
});




}
/// @nodoc
class _$CustomCategoryCopyWithImpl<$Res>
    implements $CustomCategoryCopyWith<$Res> {
  _$CustomCategoryCopyWithImpl(this._self, this._then);

  final CustomCategory _self;
  final $Res Function(CustomCategory) _then;

/// Create a copy of CustomCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? icon = null,Object? color = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomCategory].
extension CustomCategoryPatterns on CustomCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomCategory value)  $default,){
final _that = this;
switch (_that) {
case _CustomCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomCategory value)?  $default,){
final _that = this;
switch (_that) {
case _CustomCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String name,  String icon,  String color,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomCategory() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.color,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String name,  String icon,  String color,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _CustomCategory():
return $default(_that.id,_that.name,_that.icon,_that.color,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String name,  String icon,  String color,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CustomCategory() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.color,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _CustomCategory extends CustomCategory {
  const _CustomCategory({this.id, required this.name, this.icon = 'utensils', this.color = 'orange', required this.createdAt}): super._();
  

@override final  int? id;
@override final  String name;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;
@override final  String createdAt;

/// Create a copy of CustomCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomCategoryCopyWith<_CustomCategory> get copyWith => __$CustomCategoryCopyWithImpl<_CustomCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,createdAt);

@override
String toString() {
  return 'CustomCategory(id: $id, name: $name, icon: $icon, color: $color, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CustomCategoryCopyWith<$Res> implements $CustomCategoryCopyWith<$Res> {
  factory _$CustomCategoryCopyWith(_CustomCategory value, $Res Function(_CustomCategory) _then) = __$CustomCategoryCopyWithImpl;
@override @useResult
$Res call({
 int? id, String name, String icon, String color, String createdAt
});




}
/// @nodoc
class __$CustomCategoryCopyWithImpl<$Res>
    implements _$CustomCategoryCopyWith<$Res> {
  __$CustomCategoryCopyWithImpl(this._self, this._then);

  final _CustomCategory _self;
  final $Res Function(_CustomCategory) _then;

/// Create a copy of CustomCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? icon = null,Object? color = null,Object? createdAt = null,}) {
  return _then(_CustomCategory(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
