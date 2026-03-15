import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../models/category_registry.dart';
import '../providers/category_provider.dart';
import 'category_edit_sheet.dart';

@RoutePage()
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builtinAsync = ref.watch(builtinCategoriesWithCountsProvider);
    final customAsync = ref.watch(customCategoriesWithCountsProvider);

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Categories'),
        prefixes: [FHeaderAction.back(onPress: () => context.router.maybePop())],
      ),
      child: builtinAsync.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(
          child: FAlert(
            variant: FAlertVariant.destructive,
            title: const Text('Error'),
            subtitle: Text('$e'),
          ),
        ),
        data: (builtinList) => customAsync.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(
            child: FAlert(
              variant: FAlertVariant.destructive,
              title: const Text('Error'),
              subtitle: Text('$e'),
            ),
          ),
          data: (customList) => _CategoryManagementBody(
            builtinList: builtinList,
            customList: customList,
          ),
        ),
      ),
    );
  }
}

class _CategoryManagementBody extends ConsumerWidget {
  final List<BuiltInCategoryWithCount> builtinList;
  final List<CustomCategoryWithCount> customList;

  const _CategoryManagementBody({
    required this.builtinList,
    required this.customList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final customCount = customList.length;
    final isLimitReached = customCount >= 20;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Built-in section label
        Text(
          'Built-in',
          style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
        ),
        const SizedBox(height: 8),

        // Built-in category rows
        for (final item in builtinList) _BuiltInRow(item: item),

        const SizedBox(height: 24),

        // Custom section label
        Text(
          isLimitReached ? 'Custom ($customCount/20)' : 'Custom',
          style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
        ),
        const SizedBox(height: 8),

        // Custom categories or empty state
        if (customList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  'No custom categories yet',
                  style: theme.typography.base.copyWith(color: theme.colors.mutedForeground),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create one to organize expenses your way.',
                  style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                ),
              ],
            ),
          )
        else
          for (final item in customList)
            _CustomRow(
              item: item,
              allBuiltin: builtinList,
              allCustom: customList,
            ),

        const SizedBox(height: 12),

        // Add button or limit note
        if (isLimitReached)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "You've reached the 20 category limit.",
              style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          )
        else
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => _addCategory(context, ref),
            prefix: const Icon(FIcons.plus),
            child: const Text('Add Category'),
          ),
      ],
    );
  }

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final name = await showCategoryEditSheet(context);
    if (name != null && context.mounted) {
      showFToast(
        context: context,
        title: const Text('Created'),
        description: Text("Category '$name' created"),
      );
    }
  }
}

// --- Built-in row (non-interactive) ---

class _BuiltInRow extends StatelessWidget {
  final BuiltInCategoryWithCount item;

  const _BuiltInRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cat = item.cat;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(cat.icon, color: colorFromKey(cat.color), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(cat.label, style: theme.typography.base),
          ),
          Text(
            '${item.count}',
            style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

// --- Custom row (interactive) ---

class _CustomRow extends ConsumerWidget {
  final CustomCategoryWithCount item;
  final List<BuiltInCategoryWithCount> allBuiltin;
  final List<CustomCategoryWithCount> allCustom;

  const _CustomRow({
    required this.item,
    required this.allBuiltin,
    required this.allCustom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final cat = item.cat;
    final iconData = kCategoryIconSet[cat.icon] ?? FIcons.circle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(iconData, color: colorFromKey(cat.color), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(cat.name, style: theme.typography.base),
          ),
          Text(
            '${item.count}',
            style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showActionSheet(context, ref),
            child: Icon(FIcons.ellipsisVertical, size: 18, color: theme.colors.mutedForeground),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final cat = item.cat;
    final iconData = kCategoryIconSet[cat.icon] ?? FIcons.circle;

    showFSheet(
      context: context,
      side: FLayout.btt,
      useSafeArea: true,
      mainAxisMaxRatio: null,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colors.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Category header
            Row(
              children: [
                Icon(iconData, color: colorFromKey(cat.color), size: 20),
                const SizedBox(width: 8),
                Text(
                  cat.name,
                  style: theme.typography.xl2.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Edit
            GestureDetector(
              onTap: () async {
                Navigator.pop(sheetContext);
                final name = await showCategoryEditSheet(context, existing: cat);
                if (name != null && context.mounted) {
                  showFToast(
                    context: context,
                    title: const Text('Saved'),
                    description: Text("Category renamed to '$name'"),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(FIcons.pencil, size: 18),
                    const SizedBox(width: 12),
                    Text('Edit', style: theme.typography.base),
                  ],
                ),
              ),
            ),

            // Merge
            GestureDetector(
              onTap: () {
                Navigator.pop(sheetContext);
                _showMergeTargetPicker(context, ref);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(FIcons.merge, size: 18),
                    const SizedBox(width: 12),
                    Text('Merge into...', style: theme.typography.base),
                  ],
                ),
              ),
            ),

            // Delete
            GestureDetector(
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteConfirm(context, ref);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(FIcons.trash2, size: 18, color: theme.colors.destructive),
                    const SizedBox(width: 12),
                    Text(
                      'Delete',
                      style: theme.typography.base.copyWith(color: theme.colors.destructive),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMergeTargetPicker(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final cat = item.cat;

    // Build merge targets: all built-in + all custom except source
    final targets = <({String label, String targetKey, IconData icon, String color, int count})>[];

    for (final b in allBuiltin) {
      targets.add((
        label: b.cat.label,
        targetKey: b.cat.slug,
        icon: b.cat.icon,
        color: b.cat.color,
        count: b.count,
      ));
    }
    for (final c in allCustom) {
      if (c.cat.id == cat.id) continue;
      targets.add((
        label: c.cat.name,
        targetKey: c.cat.name,
        icon: kCategoryIconSet[c.cat.icon] ?? FIcons.circle,
        color: c.cat.color,
        count: c.count,
      ));
    }

    showFSheet(
      context: context,
      side: FLayout.btt,
      useSafeArea: true,
      mainAxisMaxRatio: null,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                "Merge '${cat.name}' into...",
                style: theme.typography.xl2.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: targets.length,
                  itemBuilder: (_, i) {
                    final t = targets[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showMergeConfirm(context, ref, t.label, t.targetKey);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(t.icon, color: colorFromKey(t.color), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(t.label, style: theme.typography.base),
                            ),
                            Text(
                              '${t.count} slips',
                              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
              FButton(
                variant: FButtonVariant.ghost,
                onPress: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMergeConfirm(
    BuildContext context,
    WidgetRef ref,
    String targetLabel,
    String targetKey,
  ) async {
    final cat = item.cat;
    final count = item.count;

    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        animation: animation,
        direction: Axis.vertical,
        title: Text("Merge '${cat.name}' into '$targetLabel'?"),
        body: Text(
          "$count transactions will be moved to '$targetLabel'. '${cat.name}' will be removed.",
        ),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FButton(
            onPress: () => Navigator.pop(dialogContext, true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(categoryMutationsProvider.notifier).mergeCategory(cat.id!, targetKey);
      if (context.mounted) {
        showFToast(
          context: context,
          title: const Text('Merged'),
          description: Text("'${cat.name}' merged into '$targetLabel'"),
        );
      }
    }
  }

  Future<void> _showDeleteConfirm(BuildContext context, WidgetRef ref) async {
    final cat = item.cat;
    final count = item.count;

    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        animation: animation,
        direction: Axis.vertical,
        title: Text("Delete '${cat.name}'?"),
        body: Text(
          "$count transactions will be moved to 'Other'. This can't be undone.",
        ),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(categoryMutationsProvider.notifier).deleteCategory(cat.id!);
      if (context.mounted) {
        showFToast(
          context: context,
          title: const Text('Deleted'),
          description: Text(
            "'${cat.name}' deleted. $count transactions moved to 'Other'.",
          ),
        );
      }
    }
  }
}
