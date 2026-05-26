import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isTimerFinished = false;
  bool _isAuthResolved = false;
  AuthState? _resolvedState;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Check if Auth state is already resolved on startup
    final currentState = context.read<AuthBloc>().state;
    if (currentState is Authenticated || currentState is Unauthenticated || currentState is AuthError) {
      _resolvedState = currentState;
      _isAuthResolved = true;
    }

    // Minimum display timer for premium brand loading
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isTimerFinished = true;
        });
        _checkAndNavigate();
      }
    });
  }

  void _checkAndNavigate() {
    if (!_isTimerFinished || !_isAuthResolved || !mounted) return;

    if (_resolvedState is Authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FeedScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is Unauthenticated || state is AuthError) {
          _resolvedState = state;
          _isAuthResolved = true;
          _checkAndNavigate();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background circles (optional faint style)
          Positioned(
            top: -150,
            left: -100,
            child: _buildFaintCircle(300),
          ),
          Positioned(
            bottom: -200,
            right: -150,
            child: _buildFaintCircle(400),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // App Name
                const Text(
                  'Learnex',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'Học tập cùng cộng đồng',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                // Progress bar
                SizedBox(
                  width: 200,
                  height: 4,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: const Color(0xFFEEF2FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                        borderRadius: BorderRadius.circular(2),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Footer
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'PREMIUM EDUCATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: Color(0xFFD1D5DB),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFaintCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFF3F4F6).withValues(alpha: 0.5),
          width: 40,
        ),
      ),
    );
  }
}
