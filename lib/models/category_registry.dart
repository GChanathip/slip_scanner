import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A built-in expense category with display metadata.
class BuiltInCategory {
  final String slug;
  final String label;
  final IconData icon;
  final String color;
  final String emoji;

  const BuiltInCategory({
    required this.slug,
    required this.label,
    required this.icon,
    required this.color,
    required this.emoji,
  });
}

/// All 14 built-in expense categories.
const kBuiltInCategories = <BuiltInCategory>[
  BuiltInCategory(slug: 'food', label: 'Food', icon: FIcons.utensils, color: 'orange', emoji: '🍔'),
  BuiltInCategory(slug: 'transport', label: 'Transport', icon: FIcons.car, color: 'indigo', emoji: '🚕'),
  BuiltInCategory(slug: 'utilities', label: 'Utilities', icon: FIcons.zap, color: 'yellow', emoji: '💡'),
  BuiltInCategory(slug: 'shopping', label: 'Shopping', icon: FIcons.shoppingBag, color: 'pink', emoji: '🛍️'),
  BuiltInCategory(slug: 'transfer', label: 'Transfer', icon: FIcons.arrowRightLeft, color: 'teal', emoji: '💸'),
  BuiltInCategory(slug: 'entertainment', label: 'Entertainment', icon: FIcons.gamepad2, color: 'purple', emoji: '🎬'),
  BuiltInCategory(slug: 'health', label: 'Health', icon: FIcons.heart, color: 'red', emoji: '💊'),
  BuiltInCategory(slug: 'education', label: 'Education', icon: FIcons.graduationCap, color: 'indigo', emoji: '📚'),
  BuiltInCategory(slug: 'rent', label: 'Rent', icon: FIcons.house, color: 'green', emoji: '🏠'),
  BuiltInCategory(slug: 'subscriptions', label: 'Subscriptions', icon: FIcons.repeat, color: 'purple', emoji: '📱'),
  BuiltInCategory(slug: 'groceries', label: 'Groceries', icon: FIcons.shoppingCart, color: 'green', emoji: '🛒'),
  BuiltInCategory(slug: 'personal_care', label: 'Personal Care', icon: FIcons.sparkles, color: 'pink', emoji: '💆'),
  BuiltInCategory(slug: 'gifts', label: 'Gifts', icon: FIcons.gift, color: 'red', emoji: '🎁'),
  BuiltInCategory(slug: 'other', label: 'Other', icon: FIcons.circle, color: 'teal', emoji: '📋'),
];

/// All built-in category slugs (ordered).
final List<String> kBuiltInCategorySlugs =
    kBuiltInCategories.map((c) => c.slug).toList(growable: false);

/// Index for O(1) slug lookup.
final Map<String, BuiltInCategory> _builtInBySlug = {
  for (final c in kBuiltInCategories) c.slug: c,
};

/// Find a built-in category by slug, or null if not found.
BuiltInCategory? findBuiltInBySlug(String slug) => _builtInBySlug[slug];

/// Whether the given slug is a built-in category.
bool isBuiltInCategory(String slug) => _builtInBySlug.containsKey(slug);

/// Color palette for categories (UX spec).
const kCategoryColorPalette = <String, String>{
  'orange': '#F97316',
  'red': '#EF4444',
  'pink': '#EC4899',
  'purple': '#A855F7',
  'indigo': '#6366F1',
  'teal': '#14B8A6',
  'green': '#22C55E',
  'yellow': '#EAB308',
};

/// Icon set for categories (UX spec).
const kCategoryIconSet = <String, IconData>{
  'utensils': FIcons.utensils,
  'coffee': FIcons.coffee,
  'shoppingBag': FIcons.shoppingBag,
  'car': FIcons.car,
  'zap': FIcons.zap,
  'gamepad2': FIcons.gamepad2,
  'heart': FIcons.heart,
  'graduationCap': FIcons.graduationCap,
  'home': FIcons.house,
  'briefcase': FIcons.briefcase,
  'gift': FIcons.gift,
  'plane': FIcons.plane,
  'music': FIcons.music,
  'camera': FIcons.camera,
  'dumbbell': FIcons.dumbbell,
  'tv': FIcons.tv,
};

/// Get the display icon for a category slug (built-in or custom fallback).
IconData getCategoryIcon(String? slug) {
  if (slug == null) return FIcons.circle;
  return _builtInBySlug[slug]?.icon ?? FIcons.circle;
}

/// Get the color key for a category slug.
String getCategoryColor(String? slug) {
  if (slug == null) return 'teal';
  return _builtInBySlug[slug]?.color ?? 'teal';
}

/// Get the display label for a category slug.
String getCategoryLabel(String? slug) {
  if (slug == null || slug.isEmpty) return 'Other';
  final builtIn = _builtInBySlug[slug];
  if (builtIn != null) return builtIn.label;
  // Fallback: title-case the slug
  return slug
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Get the emoji for a category slug.
String getCategoryEmoji(String? slug) {
  if (slug == null) return '📋';
  return _builtInBySlug[slug]?.emoji ?? '📋';
}

/// Validate a category slug — returns the slug if valid, otherwise 'other'.
String validateCategorySlug(String? slug) {
  if (slug == null) return 'other';
  final normalized = slug.toLowerCase().trim();
  return isBuiltInCategory(normalized) ? normalized : 'other';
}
