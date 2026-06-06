import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onHomeTap,
    required this.onFolderTap,
    required this.onAddTap,
    required this.onChatTap,
    required this.onMeetingTap,
  });

  final int currentIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onFolderTap;
  final VoidCallback onAddTap;
  final VoidCallback onChatTap;
  final VoidCallback onMeetingTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 20,
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
            _buildNavItem(
              context,
              icon: Icons.home,
              label: 'Home',
              isActive: currentIndex == 0,
              onTap: onHomeTap,
            ),
            _buildNavItem(
              context,
              icon: Icons.folder_outlined,
              label: 'Folder',
              isActive: currentIndex == 1,
              onTap: onFolderTap,
            ),
            _buildNavItem(
              context,
              icon: Icons.add_circle,
              label: 'Add',
              isPrimary: true,
              onTap: onAddTap,
            ),
            _buildNavItem(
              context,
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              isActive: currentIndex == 3,
              onTap: onChatTap,
            ),
            _buildNavItem(
              context,
              icon: Icons.groups_outlined,
              label: 'Meeting',
              isActive: currentIndex == 4,
              onTap: onMeetingTap,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final color = isActive || isPrimary ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: isPrimary ? 32 : 24,
              ),
              if (!isPrimary) const SizedBox(height: 4),
              if (!isPrimary)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
