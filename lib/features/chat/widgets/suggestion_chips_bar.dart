import 'package:avers/features/chat/models/suggestion_chip.dart' as model;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A horizontally scrollable row of suggestion chips rendered above the chat input.
class SuggestionChipsBar extends StatelessWidget {
  final List<model.SuggestionChip> chips;
  final ValueChanged<model.SuggestionChip> onChipTap;

  const SuggestionChipsBar({
    super.key,
    required this.chips,
    required this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return FButton(
            variant: FButtonVariant.outline,
            onPress: () => onChipTap(chip),
            child: Text(chip.label),
          );
        },
      ),
    );
  }
}
