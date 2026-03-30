import 'package:flutter/material.dart';
import '../../domain/entities/post.dart';
import '../../presentation/widgets/post_card.dart';

class MockFeedRepository {
  Future<List<PostEntity>> getFeedPosts() async {
    // Giả lập thời gian kết nối mạng (Network delay)
    await Future.delayed(const Duration(milliseconds: 1200));
    
    return [
      PostEntity(
        id: '1',
        authorName: 'Anh Nam',
        authorHandle: '@anhnam',
        authorInitials: 'AN',
        avatarColor: Colors.indigo.shade100,
        avatarTextColor: Colors.indigo.shade700,
        timeAgo: '2 giờ trước',
        content: 'Chia sẻ tài liệu Giải tích 2 tổng hợp cho các bạn đang ôn thi cuối kỳ. Đầy đủ các dạng bài tập và lời giải chi tiết nhé!',
        type: PostType.document,
        documentName: 'Giải tích 2 - Tổng hợp.pdf',
        documentSize: '4.2 MB',
        likes: 128,
        comments: 24,
      ),
      PostEntity(
        id: '2',
        authorName: 'Thảo Ly',
        authorHandle: '@thaoly',
        authorInitials: 'TL',
        avatarColor: Colors.teal.shade100,
        avatarTextColor: Colors.teal.shade900,
        timeAgo: '5 giờ trước',
        content: 'Phòng học Lập trình Web nhóm mình hôm nay đông vui quá! Mọi người cùng cố gắng hoàn thành project cuối khoá nha. 🔥',
        type: PostType.image,
        imageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        likes: 56,
        comments: 8,
      ),
      PostEntity(
        id: '3',
        authorName: 'Minh Tuấn',
        authorHandle: '@minhtuan',
        authorInitials: 'MT',
        avatarColor: Colors.orange.shade100,
        avatarTextColor: Colors.orange.shade900,
        timeAgo: '6 giờ trước',
        content: 'Tuyển thành viên tham gia hackathon 2024! Nhóm mình đang cần 1 bạn rành về Flutter và 1 bạn backend Nodejs. Sẽ build một app EdTech. Ai hứng thú thì inbox trực tiếp hoặc thả comment phía dưới để mình liên lạc nhé.',
        type: PostType.text,
        likes: 45,
        comments: 12,
      ),
      PostEntity(
        id: '4',
        authorName: 'Hải Đăng',
        authorHandle: '@haidang',
        authorInitials: 'HĐ',
        avatarColor: Colors.blue.shade100,
        avatarTextColor: Colors.blue.shade900,
        timeAgo: '1 ngày trước',
        content: 'Góc nhờ vả: Chiếc laptop của mình chạy Docker ngốn RAM quá dẫn tới Flutter build cứ bị treo cứng. Có bác nào xài dòng Legion 5 gợi ý xem có nên lên 32GB RAM luôn không hay 16GB vẫn sống qua mùa project cuối khoá?',
        type: PostType.text,
        likes: 210,
        comments: 45,
      ),
    ];
  }
}
