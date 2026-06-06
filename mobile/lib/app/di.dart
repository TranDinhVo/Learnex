import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/dio_client.dart';
import '../core/services/websocket_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/webrtc_service.dart';
import '../core/services/media_upload_service.dart';
import '../core/services/audio_service.dart';

// Auth
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

// Feed
import '../features/feed/data/datasources/feed_remote_datasource.dart';
import '../features/feed/data/repositories/feed_repository_impl.dart';
import '../features/feed/presentation/bloc/feed_bloc.dart';

// Folder/Document
import '../features/folder/data/datasources/document_remote_datasource.dart';
import '../features/folder/data/repositories/document_repository_impl.dart';
import '../features/folder/presentation/bloc/document_bloc.dart';

// Friend
import '../features/friends/data/datasources/friend_remote_datasource.dart';
import '../features/friends/data/repositories/friend_repository_impl.dart';
import '../features/friends/presentation/bloc/friend_bloc.dart';

// Chat
import '../features/chat/data/datasources/chat_remote_datasource.dart';
import '../features/chat/data/repositories/chat_repository_impl.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';

// Room
import '../features/room/data/datasources/room_remote_datasource.dart';
import '../features/room/data/repositories/room_repository_impl.dart';
import '../features/room/presentation/bloc/room_bloc.dart';
import '../features/room/presentation/bloc/room_detail_bloc.dart';

// Story
import '../features/story/data/datasources/story_remote_datasource.dart';
import '../features/story/data/repositories/story_repository_impl.dart';
import '../features/story/presentation/bloc/story_bloc.dart';

// AI
import '../features/folder/data/repositories/ai_repository.dart';

// Search
import '../features/search/data/datasources/search_remote_datasource.dart';
import '../features/search/data/repositories/search_repository_impl.dart';
import '../features/search/presentation/bloc/search_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // ── Core Services ──
  getIt.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  getIt.registerSingleton<Dio>(
    DioClient.create(storage: getIt<FlutterSecureStorage>()),
  );

  getIt.registerSingleton<AudioService>(
    AudioService(),
  );

  getIt.registerSingleton<WebSocketService>(
    WebSocketService(
      storage: getIt<FlutterSecureStorage>(),
      audioService: getIt<AudioService>(),
    ),
  );

  getIt.registerSingleton<NotificationService>(
    NotificationService(dio: getIt<Dio>()),
  );

  getIt.registerSingleton<WebRTCService>(
    WebRTCService(getIt<WebSocketService>()),
  );

  getIt.registerLazySingleton<MediaUploadService>(
    () => MediaUploadService(getIt<Dio>()),
  );

  // ── Data Sources ──
  getIt.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<FeedRemoteDatasource>(
    () => FeedRemoteDatasource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<DocumentRemoteDatasource>(
    () => DocumentRemoteDatasource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<FriendRemoteDatasource>(
    () => FriendRemoteDatasource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ChatRemoteDatasource>(
    () => ChatRemoteDatasource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<StoryRemoteDataSource>(
    () => StoryRemoteDataSource(dio: getIt<Dio>()),
  );
  getIt.registerLazySingleton<SearchRemoteDatasource>(
    () => SearchRemoteDatasource(getIt<Dio>()),
  );

  // ── Repositories ──
  getIt.registerLazySingleton<AuthRepositoryImpl>(
    () => AuthRepositoryImpl(
      datasource: getIt<AuthRemoteDatasource>(),
      storage: getIt<FlutterSecureStorage>(),
    ),
  );
  getIt.registerLazySingleton<FeedRepositoryImpl>(
    () => FeedRepositoryImpl(datasource: getIt<FeedRemoteDatasource>()),
  );
  getIt.registerLazySingleton<DocumentRepositoryImpl>(
    () => DocumentRepositoryImpl(datasource: getIt<DocumentRemoteDatasource>()),
  );
  getIt.registerLazySingleton<FriendRepositoryImpl>(
    () => FriendRepositoryImpl(datasource: getIt<FriendRemoteDatasource>()),
  );
  getIt.registerLazySingleton<ChatRepositoryImpl>(
    () => ChatRepositoryImpl(datasource: getIt<ChatRemoteDatasource>()),
  );
  getIt.registerLazySingleton<StoryRepositoryImpl>(
    () => StoryRepositoryImpl(remoteDataSource: getIt<StoryRemoteDataSource>()),
  );
  getIt.registerLazySingleton<AiRepository>(
    () => AiRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<SearchRepositoryImpl>(
    () => SearchRepositoryImpl(remoteDatasource: getIt<SearchRemoteDatasource>()),
  );

  // ── BLoCs ──
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(repository: getIt<AuthRepositoryImpl>()),
  );
  getIt.registerFactory<FeedBloc>(
    () => FeedBloc(
      repository: getIt<FeedRepositoryImpl>(),
      wsService: getIt<WebSocketService>(),
    ),
  );
  getIt.registerFactory<DocumentBloc>(
    () => DocumentBloc(repository: getIt<DocumentRepositoryImpl>()),
  );
  getIt.registerFactory<FriendBloc>(
    () => FriendBloc(repository: getIt<FriendRepositoryImpl>()),
  );
  // ── Chat ──
  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(
      repository: getIt<ChatRepositoryImpl>(),
      wsService: getIt<WebSocketService>(),
    ),
  );

  // ── Room ──
  getIt.registerLazySingleton<RoomRemoteDatasource>(
    () => RoomRemoteDatasource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<RoomRepositoryImpl>(
    () => RoomRepositoryImpl(datasource: getIt<RoomRemoteDatasource>()),
  );
  getIt.registerFactory<RoomBloc>(
    () => RoomBloc(
      repository: getIt<RoomRepositoryImpl>(),
      wsService: getIt<WebSocketService>(),
    ),
  );
  getIt.registerFactory<RoomDetailBloc>(
    () => RoomDetailBloc(
      repository: getIt<RoomRepositoryImpl>(),
      wsService: getIt<WebSocketService>(),
    ),
  );

  // ── Story ──
  getIt.registerFactory<StoryBloc>(
    () => StoryBloc(
      repository: getIt<StoryRepositoryImpl>(),
      wsService: getIt<WebSocketService>(),
      dio: getIt<Dio>(),
    ),
  );

  // ── Search ──
  getIt.registerFactory<SearchBloc>(
    () => SearchBloc(repository: getIt<SearchRepositoryImpl>()),
  );
}
