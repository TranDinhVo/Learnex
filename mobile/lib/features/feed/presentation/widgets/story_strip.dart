import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../story/domain/models/story_model.dart';
import '../../../story/presentation/bloc/story_bloc.dart';
import '../../../story/presentation/bloc/story_event.dart';
import '../../../story/presentation/bloc/story_state.dart';
import '../../../story/presentation/screens/create_story_screen.dart';
import '../../../story/presentation/screens/story_viewer_screen.dart';

class StoryStrip extends StatefulWidget {
  const StoryStrip({super.key});

  @override
  State<StoryStrip> createState() => _StoryStripState();
}

class _StoryStripState extends State<StoryStrip> {
  @override
  void initState() {
    super.initState();
    context.read<StoryBloc>().add(LoadStoryFeedEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get current user initial dynamically from AuthBloc
    final authState = context.read<AuthBloc>().state;
    String userInitials = 'U';
    if (authState is Authenticated) {
      final name = authState.user.fullName;
      userInitials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: BlocBuilder<StoryBloc, StoryState>(
        builder: (context, state) {
          List<StoryModel> myStories = [];
          List<FriendStoryGroup> friendStories = [];

          if (state is StoryFeedLoaded) {
            myStories = state.myStories;
            friendStories = state.friendStories;
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAddStoryButton(theme, context, userInitials, authState is Authenticated ? authState.user.avatarUrl : null),
                
                if (myStories.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  _buildUserStory(
                    theme, 
                    context, 
                    userInitials, 
                    authState is Authenticated ? authState.user.avatarUrl : null, 
                    myStories,
                    authState is Authenticated ? authState.user.fullName : 'Bạn',
                  ),
                ],
                
                if (state is StoryFeedLoading) ...[
                  const SizedBox(width: 16),
                  const Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ] else if (friendStories.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  ...List.generate(friendStories.length, (index) {
                    final friendGroup = friendStories[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < friendStories.length - 1 ? 16.0 : 0.0,
                      ),
                      child: _buildFriendStory(
                        theme, 
                        context,
                        friendGroup.userName, 
                        friendGroup.userAvatar,
                        friendGroup.hasUnseen,
                        friendGroup.stories,
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddStoryButton(ThemeData theme, BuildContext context, String initials, String? avatarUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
        );
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(avatarUrl, fit: BoxFit.cover, width: 56, height: 56)
                    : Text(
                        initials,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              'Tạo tin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStory(ThemeData theme, BuildContext context, String initials, String? avatarUrl, List<StoryModel> myStories, String userName) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StoryViewerScreen(
              stories: myStories, 
              isMyStory: true,
              userName: userName,
              userAvatar: avatarUrl,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(avatarUrl, fit: BoxFit.cover, width: 56, height: 56)
                    : Text(
                        initials,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              'Tin của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendStory(ThemeData theme, BuildContext context, String name, String? imageUrl, bool hasUnseen, List<StoryModel> stories) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StoryViewerScreen(
              stories: stories, 
              isMyStory: false,
              userName: name,
              userAvatar: imageUrl,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasUnseen 
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      )
                    : null,
                  color: hasUnseen ? null : Colors.grey.shade300,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primaryContainer,
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                          )
                        : Text(
                            initials,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: hasUnseen ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
