import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_category.freezed.dart';

@freezed
abstract class CustomCategory with _$CustomCategory {

  const factory CustomCategory({
    int? id,
    required String name,
    @Default('utensils') String icon,
    @Default('orange') String color,
    required String createdAt,
  }) = _CustomCategory;
  const CustomCategory._();

  factory CustomCategory.fromMap(Map<String, dynamic> map) => CustomCategory(
        id: map['id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String,
        color: map['color'] as String,
        createdAt: map['createdAt'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'createdAt': createdAt,
      };
}
