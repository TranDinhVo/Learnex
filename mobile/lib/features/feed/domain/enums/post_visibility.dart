import 'package:flutter/material.dart';

enum PostVisibility {
  public,
  friends,
  except,
  private,
}

extension PostVisibilityExtension on PostVisibility {
  String get label {
    switch (this) {
      case PostVisibility.public:
        return 'Công khai';
      case PostVisibility.friends:
        return 'Bạn bè';
      case PostVisibility.except:
        return 'Loại trừ';
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
      case PostVisibility.except:
        return 'Bạn bè ngoại trừ một số người';
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
      case PostVisibility.except:
        return 'except';
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
      case PostVisibility.except:
        return Icons.people_outline;
      case PostVisibility.private:
        return Icons.lock;
    }
  }
}
