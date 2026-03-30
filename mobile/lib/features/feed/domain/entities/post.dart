import 'package:flutter/material.dart';
import '../../presentation/widgets/post_card.dart';

class PostEntity {
  final String id;
  final String authorName;
  final String authorHandle;
  final String authorInitials;
  final Color avatarColor;
  final Color avatarTextColor;
  final String timeAgo;
  final String content;
  final PostType type;
  
  // Attachments
  final String? imageUrl;
  final String? documentName;
  final String? documentSize;
  
  // Stats
  final int likes;
  final int comments;

  const PostEntity({
    required this.id,
    required this.authorName,
    required this.authorHandle,
    required this.authorInitials,
    required this.avatarColor,
    required this.avatarTextColor,
    required this.timeAgo,
    required this.content,
    this.type = PostType.text,
    this.imageUrl,
    this.documentName,
    this.documentSize,
    required this.likes,
    required this.comments,
  });
}
