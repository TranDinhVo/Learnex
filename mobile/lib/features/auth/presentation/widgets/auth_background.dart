import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -MediaQuery.of(context).size.width * 0.1,
            right: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigo.shade50.withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.shade50.withValues(alpha: 0.3),
                    blurRadius: 100,
                    spreadRadius: 20,
                  )
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.width * 0.05,
            left: -MediaQuery.of(context).size.width * 0.05,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.width * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyan.shade50.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.shade50.withValues(alpha: 0.2),
                    blurRadius: 80,
                    spreadRadius: 20,
                  )
                ],
              ),
            ),
          ),
          // Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}
