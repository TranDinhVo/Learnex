import '../../domain/models/story_model.dart';
import '../datasources/story_remote_datasource.dart';

class StoryRepositoryImpl {
  final StoryRemoteDataSource remoteDataSource;

  StoryRepositoryImpl({required this.remoteDataSource});

  Future<Map<String, dynamic>> createStory({
    String? mediaUrl,
    String mediaType = 'image',
    String? textContent,
    String? textColor,
    String? bgColor,
    String? bgGradient,
    int durationSec = 5,
    String visibility = 'friends',
    List<String>? excludedUserIds,
  }) async {
    final data = {
      'media_url': mediaUrl,
      'media_type': mediaType,
      'text_content': textContent,
      'text_color': textColor,
      'bg_color': bgColor,
      'bg_gradient': bgGradient,
      'duration_sec': durationSec,
      'visibility': visibility,
      if (excludedUserIds != null) 'excluded_user_ids': excludedUserIds,
    };
    return await remoteDataSource.createStory(data);
  }

  Future<Map<String, dynamic>> getFeedStories() async {
    return await remoteDataSource.getFeedStories();
  }

  Future<List<StoryModel>> getArchive() async {
    final response = await remoteDataSource.getArchive();
    final data = response['data'] as List? ?? [];
    return data.map((json) => StoryModel.fromJson(json)).toList();
  }

  Future<void> viewStory(String id) async {
    await remoteDataSource.viewStory(id);
  }

  Future<void> reactStory(String id, String emoji) async {
    await remoteDataSource.reactStory(id, emoji);
  }

  Future<Map<String, dynamic>> getStoryViewers(String id) async {
    return await remoteDataSource.getStoryViewers(id);
  }
}
