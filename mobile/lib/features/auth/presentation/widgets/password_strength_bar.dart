import 'package:flutter/material.dart';

class PasswordStrengthBar extends StatelessWidget {
  final int strength; // 0 to 4
  final String? password;

  const PasswordStrengthBar({
    super.key, 
    required this.strength,
    this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index < strength;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 4.0 : 0),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
