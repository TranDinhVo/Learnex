import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
  });

  String _getInitials() {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || name.trim().isEmpty) return '?';
    if (words.length == 1) {
      final w = words[0];
      return w.substring(0, w.length > 2 ? 2 : w.length).toUpperCase();
    }
    return (words[0][0] + words.last[0]).toUpperCase();
  }

  Color _getColor() {
    if (backgroundColor != null) return backgroundColor!;
    final colors = [
      Colors.indigo.shade600,
      Colors.amber.shade700,
      Colors.red.shade600,
      Colors.blue.shade600,
      Colors.teal.shade600,
      Colors.purple.shade600,
      Colors.green.shade600,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: Colors.grey.shade200,
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getColor(),
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
