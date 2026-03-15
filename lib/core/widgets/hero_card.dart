import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class HeroCard extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final Color foregroundColor;
  final IconData icon;
  final String title;
  final String subtitle;

  const HeroCard({
    super.key,
    required this.onTap,
    required this.color,
    required this.foregroundColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: theme.style.borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
            borderRadius: theme.style.borderRadius,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: theme.style.borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: foregroundColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: foregroundColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(color: foregroundColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(color: foregroundColor.withValues(alpha: 0.9), fontSize: 14)),
                      ],
                    ),
                  ),
                  Icon(FIcons.arrowRight, color: foregroundColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
