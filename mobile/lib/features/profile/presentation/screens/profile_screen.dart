import 'package:flutter/material.dart';
import '../widgets/profile_header.dart';
import 'edit_profile_screen.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../feed/presentation/screens/create_post_screen.dart';
import '../../../folder/presentation/screens/folder_overview_screen.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                elevation: 0,
                pinned: true,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurfaceVariant, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  'Hồ sơ cá nhân',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () {},
                  ),
                ],
              ),

              // Profile Header
              SliverToBoxAdapter(
                child: ProfileHeader(
                  name: 'Nguyễn Tú Anh',
                  username: 'tuanh2021',
                  bio: 'Đam mê xây dựng ứng dụng di động và chia sẻ kiến thức thuật toán. Đang nghiên cứu về AI trong giáo dục.',
                  school: 'UIT',
                  major: 'Khoa học Máy tính',
                  initials: 'TA',
                  onEditTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
              ),

              // Stats Row
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 1),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('142', 'Bài đăng', theme),
                      _buildStatItem('1.2k', 'Bạn bè', theme),
                      _buildStatItem('28', 'Tài liệu', theme),
                    ],
                  ),
                ),
              ),

              // Settings Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'CÀI ĐẶT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.person_outline,
                        title: 'Chỉnh sửa hồ sơ',
                        theme: theme,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.lock_outline,
                        title: 'Đổi mật khẩu',
                        theme: theme,
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildSettingsSwitch(
                        icon: Icons.dark_mode_outlined,
                        title: 'Chế độ tối',
                        value: _isDarkMode,
                        theme: theme,
                        onChanged: (val) {
                          setState(() {
                            _isDarkMode = val;
                          });
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsSwitch(
                        icon: Icons.notifications_outlined,
                        title: 'Thông báo',
                        value: _isNotificationsEnabled,
                        theme: theme,
                        onChanged: (val) {
                          setState(() {
                            _isNotificationsEnabled = val;
                          });
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.info_outline,
                        title: 'Về ứng dụng',
                        theme: theme,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

              // Logout Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.logout, color: theme.colorScheme.error, size: 20),
                      label: Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Navigation overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNavBar(
              currentIndex: -1,
              onHomeTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const FeedScreen()),
                );
              },
              onFolderTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const FolderOverviewScreen()),
                );
              },
              onAddTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
              onChatTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              },
              onMeetingTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng Meeting đang được phát triển.')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ThemeData theme,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 54, endIndent: 16);
  }
}
