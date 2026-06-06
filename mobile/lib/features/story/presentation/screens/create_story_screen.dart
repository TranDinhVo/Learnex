import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../bloc/story_bloc.dart';
import '../bloc/story_event.dart';
import '../bloc/story_state.dart';
import '../widgets/friend_picker_bottom_sheet.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  bool _isTextMode = false;
  String? _selectedMediaPath;
  String _mediaType = 'image';
  VideoPlayerController? _videoController;
  
  // Text Mode variables
  final TextEditingController _textController = TextEditingController();
  final List<List<Color>> _gradientPresets = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
    [const Color(0xFF84FAB0), const Color(0xFF8FD3F4)],
    [const Color(0xFFFA709A), const Color(0xFFFEE140)],
    [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
    [const Color(0xFF30CFD0), const Color(0xFF330867)],
    [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
  ];
  int _currentGradientIndex = 0;
  
  final ImagePicker _picker = ImagePicker();
  String _visibility = 'friends';
  List<String> _excludedUserIds = [];

  @override
  void dispose() {
    _textController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final XFile? media = await _picker.pickMedia(imageQuality: 80);
    if (media != null) {
      final ext = media.path.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
      
      _videoController?.dispose();
      _videoController = null;
      
      if (isVideo) {
        _videoController = VideoPlayerController.file(File(media.path))
          ..initialize().then((_) {
            setState(() {});
            _videoController?.setLooping(true);
            _videoController?.play();
          });
      }

      setState(() {
        _selectedMediaPath = media.path;
        _mediaType = isVideo ? 'video' : 'image';
        _isTextMode = false;
      });
    }
  }

  void _submitStory() {
    if (_isTextMode) {
      if (_textController.text.trim().isEmpty) return;
      
      final gradient = _gradientPresets[_currentGradientIndex];
      // Convert colors to hex
      final hexColors = gradient.map((c) => '#${c.value.toRadixString(16).substring(2).toUpperCase()}').toList();
      
      context.read<StoryBloc>().add(CreateStoryEvent(
        mediaType: 'text',
        textContent: _textController.text.trim(),
        bgGradient: '["${hexColors[0]}", "${hexColors[1]}"]', // simple JSON array representation
        textColor: '#FFFFFF',
        visibility: _visibility,
        excludedUserIds: _visibility == 'except' ? _excludedUserIds : null,
      ));
    } else {
      if (_selectedMediaPath == null) return;
      
      context.read<StoryBloc>().add(CreateStoryEvent(
        mediaPath: _selectedMediaPath,
        mediaType: _mediaType,
        visibility: _visibility,
        excludedUserIds: _visibility == 'except' ? _excludedUserIds : null,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StoryBloc, StoryState>(
      listener: (context, state) {
        if (state is StoryCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đăng tin thành công!')),
          );
          Navigator.of(context).pop();
        } else if (state is StoryCreateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Tạo tin mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            BlocBuilder<StoryBloc, StoryState>(
              builder: (context, state) {
                if (state is StoryCreating) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 24, height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      ),
                    ),
                  );
                }
                
                final canSubmit = (_isTextMode && _textController.text.trim().isNotEmpty) || 
                                 (!_isTextMode && _selectedMediaPath != null);
                
                return TextButton(
                  onPressed: canSubmit ? _submitStory : null,
                  child: Text(
                    'Đăng',
                    style: TextStyle(
                      color: canSubmit ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildStoryPreview(),
                  ),
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryPreview() {
    if (_isTextMode || _selectedMediaPath == null) {
      // Text Mode or Initial state
      return GestureDetector(
        onTap: () {
          if (_isTextMode) {
            setState(() {
              _currentGradientIndex = (_currentGradientIndex + 1) % _gradientPresets.length;
            });
          }
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _gradientPresets[_currentGradientIndex],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isTextMode 
                ? TextField(
                    controller: _textController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Chạm để nhập chữ...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                    onChanged: (_) => setState(() {}),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.amp_stories, size: 64, color: Colors.white.withOpacity(0.8)),
                      const SizedBox(height: 16),
                      const Text(
                        'Chọn chế độ bên dưới để bắt đầu',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      );
    } else {
      // Media Mode
      return Stack(
        fit: StackFit.expand,
        children: [
          if (_mediaType == 'video' && _videoController != null && _videoController!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            Image.file(
              File(_selectedMediaPath!),
              fit: BoxFit.cover,
            ),
          // Gradient overlay for better text visibility if we add text later
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: Colors.black87,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Privacy Selector
          GestureDetector(
            onTap: _showPrivacySelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getPrivacyIcon(), color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _getPrivacyLabel(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Mode Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModeButton(
                icon: Icons.photo_library,
                label: 'Thư viện',
                isSelected: !_isTextMode && _selectedMediaPath != null,
                onTap: _pickMedia,
              ),
              _buildModeButton(
                icon: Icons.text_fields,
                label: 'Văn bản',
                isSelected: _isTextMode,
                onTap: () {
                  setState(() {
                    _isTextMode = true;
                    _selectedMediaPath = null;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPrivacyIcon() {
    switch (_visibility) {
      case 'public': return Icons.public;
      case 'friends': return Icons.people;
      case 'except': return Icons.person_off;
      case 'private': return Icons.lock;
      default: return Icons.people;
    }
  }

  String _getPrivacyLabel() {
    switch (_visibility) {
      case 'public': return 'Công khai';
      case 'friends': return 'Bạn bè';
      case 'except': return 'Bạn bè ngoại trừ...';
      case 'private': return 'Chỉ mình tôi';
      default: return 'Bạn bè';
    }
  }

  void _showPrivacySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Ai có thể xem tin của bạn?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildPrivacyOption('public', 'Công khai', Icons.public),
            _buildPrivacyOption('friends', 'Bạn bè', Icons.people),
            _buildPrivacyOption('except', 'Bạn bè ngoại trừ...', Icons.person_off),
            _buildPrivacyOption('private', 'Chỉ mình tôi', Icons.lock),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(String value, String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: _visibility == value ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () async {
        Navigator.pop(context);
        
        if (value == 'except') {
          final result = await FriendPickerBottomSheet.show(context, _excludedUserIds);
          if (result != null) {
            setState(() {
              _excludedUserIds = result;
              _visibility = value;
            });
          }
        } else {
          setState(() {
            _visibility = value;
            _excludedUserIds = [];
          });
        }
      },
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white12,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(icon, color: isSelected ? Colors.blue : Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
