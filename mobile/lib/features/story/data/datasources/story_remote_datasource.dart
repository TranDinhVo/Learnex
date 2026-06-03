import 'package:dio/dio.dart';

class StoryRemoteDataSource {
  final Dio dio;

  StoryRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) async {
    final response = await dio.post('/stories', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getFeedStories() async {
    final response = await dio.get('/stories/feed');
    return response.data;
  }

  Future<Map<String, dynamic>> getArchive() async {
    final response = await dio.get('/stories/archive');
    return response.data;
  }

  Future<void> viewStory(String id) async {
    await dio.post('/stories/$id/view');
  }

  Future<void> reactStory(String id, String emoji) async {
    await dio.post('/stories/$id/react', data: {'emoji': emoji});
  }

  Future<Map<String, dynamic>> getStoryViewers(String id) async {
    final response = await dio.get('/stories/$id/viewers');
    return response.data;
  }
}
