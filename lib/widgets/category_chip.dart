import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A90D9)
              : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A90D9)
                : const Color(0xFFE4E8F0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A90D9)
                        .withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Emoji / Icon ─────────────────────
            Text(
              category.icon.isNotEmpty
                  ? category.icon
                  : '📍',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(width: 6),

            // ── Label ────────────────────────────
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF4A5568),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}