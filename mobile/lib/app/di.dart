import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/dio_client.dart';
import '../core/services/websocket_service.dart';
import '../core/services/notification_service.dart';

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

  getIt.registerSingleton<WebSocketService>(
    WebSocketService(storage: getIt<FlutterSecureStorage>()),
  );

  getIt.registerSingleton<NotificationService>(
    NotificationService(dio: getIt<Dio>()),
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

  // ── BLoCs ──
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(repository: getIt<AuthRepositoryImpl>()),
  );
  getIt.registerFactory<FeedBloc>(
    () => FeedBloc(repository: getIt<FeedRepositoryImpl>()),
  );
  getIt.registerFactory<DocumentBloc>(
    () => DocumentBloc(repository: getIt<DocumentRepositoryImpl>()),
  );
  getIt.registerFactory<FriendBloc>(
    () => FriendBloc(repository: getIt<FriendRepositoryImpl>()),
  );
  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(
      repository: getIt<ChatRepositoryImpl>(),
      wsService: getIt<WebSocketService>(),
    ),
  );
}
