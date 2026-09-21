import 'package:flutter/material.dart';

class SnobLogo extends StatelessWidget {
  const SnobLogo({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  static const Color snobDarkGreen = Color(0xFF164B39);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: const Text(
          'SNOB',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: snobDarkGreen,
          ),
        ),
      ),
    );
  }
}