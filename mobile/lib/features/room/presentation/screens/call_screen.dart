import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/webrtc_service.dart';
import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class CallScreen extends StatefulWidget {
  final WebRTCService webrtcService;
  final String roomId;

  const CallScreen({
    super.key,
    required this.webrtcService,
    required this.roomId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isInitializing = true;
  Offset _localVideoPosition = const Offset(16, 16);

  @override
  void initState() {
    super.initState();
    _initCall();
    
    // Lắng nghe thay đổi kết nối hoặc Media state
    widget.webrtcService.onMediaStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initCall() async {
    final authState = context.read<AuthBloc>().state;
    String currentUserId = 'unknown';
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
    }
    
    await widget.webrtcService.init(currentUserId);
    await widget.webrtcService.joinCall(widget.roomId);
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    widget.webrtcService.leaveCall();
    super.dispose();
  }

  void _toggleMute() {
    widget.webrtcService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleCamera() {
    widget.webrtcService.toggleCamera();
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
  }

  void _endCall() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final remoteRenderers = widget.webrtcService.remoteRenderers.values.toList();
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Nền tối slate hiện đại
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Ánh sáng trang trí nền
            Positioned(
              top: -100,
              left: -100,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.indigo.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            
            // Lưới Video những người tham gia
            if (_isInitializing || remoteRenderers.isEmpty)
              _buildWaitingScreen()
            else
              _buildRemoteGrid(remoteRenderers),

            // Video Camera Của Bạn (Floating Draggable)
            if (!_isCameraOff && !_isInitializing)
              Positioned(
                right: _localVideoPosition.dx,
                bottom: _localVideoPosition.dy + 120, // Tránh đè lên toolbar
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _localVideoPosition = Offset(
                        (_localVideoPosition.dx - details.delta.dx).clamp(16.0, screenSize.width - 136),
                        (_localVideoPosition.dy - details.delta.dy).clamp(16.0, screenSize.height - 290),
                      );
                    });
                  },
                  child: Container(
                    width: 120,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RTCVideoView(
                          widget.webrtcService.localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                        if (_isMuted)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mic_off, color: Colors.redAccent, size: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // Header - Nút Back và Tiêu đề Call
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _buildGlassButton(
                    icon: Icons.keyboard_arrow_down,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "00:00", // Để đẹp, sau có thể gắn Timer thật
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Toolbar điều khiển (Mute, Video, End Call) - Glassmorphism
            Positioned(
              bottom: 30,
              left: 30,
              right: 30,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildToolButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic_none,
                          isActive: _isMuted,
                          activeColor: Colors.redAccent,
                          onTap: _toggleMute,
                        ),
                        _buildCallEndButton(onTap: _endCall),
                        _buildToolButton(
                          icon: _isCameraOff ? Icons.videocam_off : Icons.videocam_outlined,
                          isActive: _isCameraOff,
                          activeColor: Colors.redAccent,
                          onTap: _toggleCamera,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Màn hình chờ phong cách hiện đại
  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_alt_outlined, size: 64, color: Colors.indigoAccent),
          ),
          const SizedBox(height: 24),
          const Text(
            "Đang chờ mọi người tham gia...",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Render lưới camera xịn xò
  Widget _buildRemoteGrid(List<RTCVideoRenderer> renderers) {
    final count = renderers.length;
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count == 1 ? 1 : 2,
        childAspectRatio: count == 1 ? 0.6 : 0.8,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RTCVideoView(
                renderers[index],
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Thành viên ${index + 1}",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildCallEndButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.call_end, color: Colors.white, size: 30),
      ),
    );
  }
}
