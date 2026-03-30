import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/login_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnEx',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3525CD),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const LoginScreen(),
    );
  }
}