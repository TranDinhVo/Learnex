import 'package:flutter/material.dart';
import '../widgets/comment_item.dart';
import '../widgets/comment_input_bar.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Bài đăng',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: theme.colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Post Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'AN',
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Anh Nam',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '12 giờ trước • Cộng đồng Giải tích 1',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        
                        // Post Content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chào mọi người, mình vừa tổng hợp xong bộ tài liệu ôn tập chương 2: Đạo hàm và Vi phân. Tài liệu này bao gồm các dạng bài tập từ cơ bản đến nâng cao, có kèm theo lời giải chi tiết cho các câu hỏi khó trong đề thi các năm trước. Hy vọng nó sẽ giúp ích cho kỳ thi giữa kỳ sắp tới của các bạn!',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Document Chip
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.picture_as_pdf, color: theme.colorScheme.error),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'On-tap-Giai-tich-Chương-2.pdf',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '2.4 MB • PDF Document',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.download, color: theme.colorScheme.onSurfaceVariant),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        
                        // Post Stats Row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildStatItem('128', 'lượt thích', theme),
                              _buildStatItem('24', 'bình luận', theme, isMiddle: true),
                              _buildStatItem('12', 'lượt lưu', theme),
                            ],
                          ),
                        ),
                        
                        // Post Action Row
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionButton(Icons.favorite, 'Thích (128)', theme.colorScheme.primary),
                              _buildActionButton(Icons.chat_bubble_outline, 'Bình luận', theme.colorScheme.onSurfaceVariant),
                              _buildActionButton(Icons.bookmark_outline, 'Lưu', theme.colorScheme.onSurfaceVariant),
                              _buildActionButton(Icons.send_outlined, 'Chia sẻ', theme.colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Comment Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bình luận (24)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Mới nhất',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Icon(Icons.expand_more, size: 20, color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Comment List
                  CommentItem(
                    authorName: 'Hoài My',
                    authorInitials: 'HM',
                    timeAgo: '2 giờ trước',
                    content: 'Cảm ơn bạn nhiều lắm! 🙏 Bộ đề này đúng lúc mình đang cần để ôn thi luôn.',
                    avatarColor: theme.colorScheme.secondaryContainer,
                    avatarTextColor: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(height: 24),
                  CommentItem(
                    authorName: 'Thanh Khoa',
                    authorInitials: 'TK',
                    timeAgo: '5 giờ trước',
                    content: 'Bạn có tài liệu Giải tích 3 không? Mình đang bị kẹt ở phần phương trình vi phân cấp cao.',
                    avatarColor: theme.colorScheme.tertiaryContainer,
                    avatarTextColor: theme.colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(height: 80), // Optional extra spacing
                ],
              ),
            ),
          ),
          
          // Bottom Input Bar
          const CommentInputBar(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, ThemeData theme, {bool isMiddle = false}) {
    return Row(
      children: [
        if (isMiddle) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('·', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        if (isMiddle) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('·', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
