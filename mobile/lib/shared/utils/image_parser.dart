import 'dart:convert';

class ImageParser {
  static List<String> parseImageUrls(dynamic imageList) {
    if (imageList == null) return [];
    
    if (imageList is List) {
      return imageList.map((e) => e.toString()).toList();
    } else if (imageList is String && imageList.isNotEmpty) {
      if (imageList.startsWith('[')) {
        try {
          final List<dynamic> parsed = jsonDecode(imageList);
          return parsed.map((e) => e.toString()).toList();
        } catch (_) {
          // Fallback manual parsing if jsonDecode fails
          final rawStr = imageList.replaceAll(RegExp('[\\[\\]"\' ]'), '');
          if (rawStr.isEmpty) return [];
          return rawStr.split(',').where((s) => s.isNotEmpty).toList();
        }
      } else {
        return [imageList];
      }
    }
    return [];
  }
}
