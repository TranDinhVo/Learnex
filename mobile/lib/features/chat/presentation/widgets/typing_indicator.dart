import 'package:flutter/material.dart';
import 'dart:math' as math;

class TypingIndicatorBubble extends StatefulWidget {
  final Color bubbleColor;
  final Color dotColor;
  final String initials;

  const TypingIndicatorBubble({
    super.key,
    this.bubbleColor = const Color(0xFFE4E6EB),
    this.dotColor = const Color(0xFF65676B),
    required this.initials,
  });

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFB6B4FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              widget.initials,
              style: const TextStyle(
                color: Color(0xFF140F54),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.bubbleColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Mỗi dấu chấm trễ 0.2s so với dấu chấm trước
        final delay = index * 0.2;
        // Chu kỳ nhấp nhô
        double progress = (_controller.value - delay);
        if (progress < 0) progress += 1.0;

        // Sine wave effect
        final sinValue = math.sin(progress * math.pi * 2);
        // Nhảy lên khi sinValue > 0, và giữ nguyên khi < 0
        final dy = sinValue > 0 ? -sinValue * 4 : 0.0;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.dotColor.withValues(alpha: sinValue > 0 ? 1.0 : 0.5),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
