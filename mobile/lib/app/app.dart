import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'di.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/feed/presentation/bloc/feed_bloc.dart';
import '../features/folder/presentation/bloc/document_bloc.dart';
import '../features/friends/presentation/bloc/friend_bloc.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
import '../features/auth/presentation/screens/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(CheckAuthEvent()),
        ),
        BlocProvider<FeedBloc>(
          create: (_) => getIt<FeedBloc>(),
        ),
        BlocProvider<DocumentBloc>(
          create: (_) => getIt<DocumentBloc>(),
        ),
        BlocProvider<FriendBloc>(
          create: (_) => getIt<FriendBloc>(),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => getIt<ChatBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'LearnEx',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF3525CD),
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}