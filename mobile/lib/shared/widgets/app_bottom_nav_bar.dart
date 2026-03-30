import 'package:flutter/material.dart';
import '../../features/feed/presentation/screens/create_post_screen.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 20,
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, icon: Icons.home, label: 'Home', isActive: true),
            _buildNavItem(context, icon: Icons.folder_outlined, label: 'Folder'),
            _buildNavItem(context, icon: Icons.add_circle, label: 'Add', isPrimary: true),
            _buildNavItem(context, icon: Icons.chat_bubble_outline, label: 'Chat'),
            _buildNavItem(context, icon: Icons.groups_outlined, label: 'Meeting'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, bool isActive = false, bool isPrimary = false}) {
    final theme = Theme.of(context);
    final color = isActive || isPrimary ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () {
        if (isPrimary) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: isPrimary ? 32 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
