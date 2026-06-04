import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'websocket_service.dart';

/// Quản lý trạng thái gọi WebRTC Mesh P2P
class WebRTCService {
  final WebSocketService _wsService;
  
  MediaStream? _localStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  
  // Map lưu trữ PeerConnection tương ứng với mỗi remote userId
  final Map<String, RTCPeerConnection> _peerConnections = {};
  // Map lưu trữ Renderer (Video) tương ứng với mỗi remote userId
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  // Cập nhật State cho UI
  final StreamController<void> _onMediaStateChanged = StreamController.broadcast();
  Stream<void> get onMediaStateChanged => _onMediaStateChanged.stream;

  // Stream thông báo khi cuộc gọi kết thúc (từ xa)
  final StreamController<void> _onCallEnded = StreamController.broadcast();
  Stream<void> get onCallEnded => _onCallEnded.stream;

  String? _currentRoomId;

  StreamSubscription? _wsSubscription;

  WebRTCService(this._wsService);

  bool _audioOnly = false;
  bool _speakerOn = false;

  Future<void> init(String myUserId, {bool audioOnly = false}) async {
    _audioOnly = audioOnly;
    await localRenderer.initialize();
    
    // Cancel existing subscription if any to prevent duplicates
    await _wsSubscription?.cancel();
    // Lắng nghe signal từ WebSocket
    _wsSubscription = _wsService.messages.listen((message) {
      final type = message['type'];
      final data = message['data'] ?? {};
      
      switch (type) {
        case 'user_joined_call':
          _handleUserJoinedCall(data['senderId']);
          break;
        case 'user_left_call':
          _handleUserLeftCall(data['senderId']);
          break;
        case 'private_call_end':
        case 'private_call_reject':
          _onCallEnded.add(null);
          break;
        case 'webrtc_offer':
          _handleOffer(data['senderId'], data['sdp']);
          break;
        case 'webrtc_answer':
          _handleAnswer(data['senderId'], data['sdp']);
          break;
        case 'webrtc_ice_candidate':
          _handleIceCandidate(data['senderId'], data['candidate']);
          break;
      }
    });
  }

  /// 1. Tham gia một cuộc gọi nhóm
  Future<void> joinCall(String roomId) async {
    _currentRoomId = roomId;
    
    // Lấy luồng local Camera/Mic
    final Map<String, dynamic> mediaConstraints = _audioOnly
        ? {'audio': true, 'video': false}
        : {
            'audio': true,
            'video': {'facingMode': 'user'},
          };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;
    } catch (e) {
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
      localRenderer.srcObject = _localStream;
    }
    _onMediaStateChanged.add(null);

    // Gửi thông báo cho room là tôi join call
    _wsService.send({
      'type': 'join_call',
      'data': {'roomId': roomId}
    });
  }

  /// 1.5. Tham gia cuộc gọi riêng tư (1-1)
  Future<void> joinPrivateCall({required String roomId, required String partnerId, required bool isCaller}) async {
    _currentRoomId = roomId;
    
    // Lấy luồng local Camera/Mic (không dùng camera nếu audioOnly)
    final Map<String, dynamic> mediaConstraints = _audioOnly
        ? {'audio': true, 'video': false}
        : {
            'audio': true,
            'video': {'facingMode': 'user'},
          };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;
    } catch (e) {
      // Fallback to audio only if camera fails
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
      localRenderer.srcObject = _localStream;
    }
    _onMediaStateChanged.add(null);

    // Chỉ Receiver mới nhắn `private_join_call` để kích hoạt Caller tạo Offer
    if (!isCaller) {
      _wsService.send({
        'type': 'private_join_call',
        'data': {'roomId': roomId, 'targetId': partnerId}
      });
    }
  }

  /// 2. Khi có user khác join call, mình là người cũ tạo Offer kết nối
  Future<void> _handleUserJoinedCall(String remoteUserId) async {
    final pc = await _createPeerConnection(remoteUserId);
    
    // Tạo Offer
    RTCSessionDescription offer = await pc.createOffer({});
    await pc.setLocalDescription(offer);

    // Gửi Offer qua WebSocket
    _wsService.send({
      'type': 'webrtc_offer',
      'data': {
        'targetId': remoteUserId,
        'roomId': _currentRoomId,
        'sdp': offer.toMap(),
      }
    });
  }

  /// 3. Người mới nhận được Offer, tạo Answer
  Future<void> _handleOffer(String remoteUserId, Map<String, dynamic> sdpMap) async {
    final pc = await _createPeerConnection(remoteUserId);
    
    await pc.setRemoteDescription(RTCSessionDescription(sdpMap['sdp'], sdpMap['type']));
    
    RTCSessionDescription answer = await pc.createAnswer({});
    await pc.setLocalDescription(answer);

    _wsService.send({
      'type': 'webrtc_answer',
      'data': {
        'targetId': remoteUserId,
        'roomId': _currentRoomId,
        'sdp': answer.toMap(),
      }
    });
  }

  /// 4. Người nhận answer cập nhật Local Description
  Future<void> _handleAnswer(String remoteUserId, Map<String, dynamic> sdpMap) async {
    final pc = _peerConnections[remoteUserId];
    if (pc != null) {
      await pc.setRemoteDescription(RTCSessionDescription(sdpMap['sdp'], sdpMap['type']));
    }
  }

  /// 5. Nhận ICE Candidate
  Future<void> _handleIceCandidate(String remoteUserId, Map<String, dynamic> candidateMap) async {
    final pc = _peerConnections[remoteUserId];
    if (pc != null) {
      final candidate = RTCIceCandidate(
          candidateMap['candidate'], candidateMap['sdpMid'], candidateMap['sdpMLineIndex']);
      await pc.addCandidate(candidate);
    }
  }

  /// Hàm Factory tạo PeerConnection chuẩn bị ICE
  Future<RTCPeerConnection> _createPeerConnection(String remoteUserId) async {
    final configuration = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };

    final pc = await createPeerConnection(configuration);
    _peerConnections[remoteUserId] = pc;

    // Gắn local stream vào PC (Cho phép P2P truyền video mình đi)
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    // Khi tìm thấy đường truyền mới
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      _wsService.send({
        'type': 'webrtc_ice_candidate',
        'data': {
          'targetId': remoteUserId,
          'roomId': _currentRoomId,
          'candidate': candidate.toMap(),
        }
      });
    };

    // Khi nhận được Media Track từ người kia
    pc.onTrack = (RTCTrackEvent event) async {
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        if (!remoteRenderers.containsKey(remoteUserId)) {
          final renderer = RTCVideoRenderer();
          await renderer.initialize();
          renderer.srcObject = stream;
          remoteRenderers[remoteUserId] = renderer;
        } else {
          remoteRenderers[remoteUserId]!.srcObject = stream;
        }
        _onMediaStateChanged.add(null);
      }
    };

    pc.onIceConnectionState = (RTCIceConnectionState state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected || 
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _handleUserLeftCall(remoteUserId);
      }
    };

    return pc;
  }

  /// Xóa kết nối khi ai đó thoát call
  void _handleUserLeftCall(String remoteUserId) {
    _peerConnections[remoteUserId]?.close();
    _peerConnections.remove(remoteUserId);
    
    remoteRenderers[remoteUserId]?.dispose();
    remoteRenderers.remove(remoteUserId);
    
    _onMediaStateChanged.add(null);
  }

  void toggleMute() {
    if (_localStream != null) {
      bool enabled = _localStream!.getAudioTracks()[0].enabled;
      _localStream!.getAudioTracks()[0].enabled = !enabled;
    }
  }

  void toggleCamera() {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      bool enabled = _localStream!.getVideoTracks()[0].enabled;
      _localStream!.getVideoTracks()[0].enabled = !enabled;
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      await Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  void toggleSpeaker() {
    _speakerOn = !_speakerOn;
    // flutter_webrtc sẽ xử lý audio routing
    // enableSpeakerphone is handled by the platform
  }

  /// Ngắt hoàn toàn cuộc gọi
  Future<void> leaveCall() async {
    _wsService.send({
      'type': 'leave_call',
      'data': {'roomId': _currentRoomId}
    });

    _peerConnections.forEach((key, pc) => pc.close());
    _peerConnections.clear();
    
    remoteRenderers.forEach((key, renderer) => renderer.dispose());
    remoteRenderers.clear();

    localRenderer.srcObject = null;
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;
    
    _currentRoomId = null;
    _onMediaStateChanged.add(null);
  }

  Future<void> dispose() async {
    await leaveCall();
    await localRenderer.dispose();
    await _wsSubscription?.cancel();
    _onMediaStateChanged.close();
    _onCallEnded.close();
  }
}
