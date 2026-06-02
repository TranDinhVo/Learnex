import 'package:flutter/material.dart';

enum PostVisibility {
  public,
  friends,
  private,
}

extension PostVisibilityExtension on PostVisibility {
  String get label {
    switch (this) {
      case PostVisibility.public:
        return 'Công khai';
      case PostVisibility.friends:
        return 'Bạn bè';
      case PostVisibility.private:
        return 'Chỉ mình tôi';
    }
  }

  String get subLabel {
    switch (this) {
      case PostVisibility.public:
        return 'Mọi người đều có thể thấy';
      case PostVisibility.friends:
        return 'Chỉ bạn bè của bạn mới thấy';
      case PostVisibility.private:
        return 'Chỉ bạn mới có thể thấy bài viết này';
    }
  }

  String get value {
    switch (this) {
      case PostVisibility.public:
        return 'public';
      case PostVisibility.friends:
        return 'friends';
      case PostVisibility.private:
        return 'private';
    }
  }

  IconData get icon {
    switch (this) {
      case PostVisibility.public:
        return Icons.public;
      case PostVisibility.friends:
        return Icons.group;
      case PostVisibility.private:
        return Icons.lock;
    }
  }
}
