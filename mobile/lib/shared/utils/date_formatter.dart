String formatTimeAgo(String? dateTimeStr) {
  if (dateTimeStr == null || dateTimeStr.isEmpty) return 'Vừa xong';
  try {
    final dateTime = DateTime.parse(dateTimeStr).toLocal();
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  } catch (_) {
    return 'Vừa xong';
  }
}
