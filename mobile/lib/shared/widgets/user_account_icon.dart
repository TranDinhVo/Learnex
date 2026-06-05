import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class UserAccountIcon extends StatelessWidget {
  const UserAccountIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String? avatarUrl;
        String initial = 'U';
        if (authState is Authenticated) {
          avatarUrl = authState.user.avatarUrl;
          initial = authState.user.fullName.isNotEmpty
              ? authState.user.fullName[0].toUpperCase()
              : 'U';
        }
        return Padding(
          padding: const EdgeInsets.only(right: 8.0, left: 4.0),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
