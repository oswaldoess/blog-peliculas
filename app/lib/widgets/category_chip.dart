import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = selected ? Colors.white : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2196F3) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: colorTexto),
              const SizedBox(width: 6),
            ],
            Text(text, style: TextStyle(color: colorTexto, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
