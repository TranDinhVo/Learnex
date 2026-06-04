import 'package:flutter/material.dart';
import '../../domain/enums/post_visibility.dart';

class PostVisibilityBottomSheet extends StatelessWidget {
  final PostVisibility currentVisibility;

  const PostVisibilityBottomSheet({
    super.key,
    required this.currentVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ai có thể xem bài viết này?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bài viết của bạn sẽ hiển thị trên bảng tin và trang cá nhân.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            _buildOption(
              context: context,
              visibility: PostVisibility.public,
              isSelected: currentVisibility == PostVisibility.public,
            ),
            _buildOption(
              context: context,
              visibility: PostVisibility.friends,
              isSelected: currentVisibility == PostVisibility.friends,
            ),
            _buildOption(
              context: context,
              visibility: PostVisibility.private,
              isSelected: currentVisibility == PostVisibility.private,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required PostVisibility visibility,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        Navigator.of(context).pop(visibility);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.colorScheme.primaryContainer 
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                visibility.icon,
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visibility.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    visibility.subLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              )
            else
              const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}
