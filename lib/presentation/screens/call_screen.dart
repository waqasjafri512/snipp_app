import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import '../providers/live_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/socket_service.dart';
import 'dart:ui';
import 'dart:async';

class CallScreen extends StatefulWidget {
  final int remoteUserId;
  final String remoteUserName;
  final String? remoteUserAvatar;
  final String type; // 'audio' or 'video'
  final String channelName;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.remoteUserId,
    required this.remoteUserName,
    this.remoteUserAvatar,
    required this.type,
    required this.channelName,
    required this.isIncoming,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isRemoteUserJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoOff = false;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _isVideoOff = widget.type == 'audio';
    _initAgora();
    _initSocket();
  }

  void _initSocket() {
    _socketSub = SocketService().eventStream.listen((event) {
      if (event['event'] == 'callAccepted') {
        // Only relevant if we were waiting for them to answer
      } else if (event['event'] == 'callRejected' || event['event'] == 'callEnded') {
        _onEndCall();
      }
    });
  }

  Future<void> _initAgora() async {
    final liveProv = Provider.of<LiveProvider>(context, listen: false);
    
    // Request permissions
    final hasPermission = await liveProv.handlePermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions denied')));
        Navigator.pop(context);
      }
      return;
    }

    // Get Agora token
    final tokenData = await liveProv.getAgoraToken(widget.channelName);
    if (tokenData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get call token')));
        Navigator.pop(context);
      }
      return;
    }

    final appId = tokenData['appId'];
    final token = tokenData['token'];
    final localUid = tokenData['uid'];

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) setState(() => _isJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted) setState(() {
            _isRemoteUserJoined = true;
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (mounted) setState(() {
            _isRemoteUserJoined = false;
            _remoteUid = null;
          });
          _onEndCall();
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          if (mounted) setState(() => _isJoined = false);
        },
      ),
    );

    if (widget.type == 'video') {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    } else {
      await _engine!.enableAudio();
    }

    await _engine!.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: localUid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  void _onToggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine?.muteLocalAudioStream(_isMuted);
  }

  void _onToggleVideo() {
    if (widget.type == 'audio') return;
    setState(() => _isVideoOff = !_isVideoOff);
    _engine?.muteLocalVideoStream(_isVideoOff);
  }

  void _onSwitchCamera() {
    _engine?.switchCamera();
  }

  void _onEndCall() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    SocketService().emit('endCall', {'to': widget.remoteUserId});
    
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.primaryGradient;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Remote Video
          Positioned.fill(
            child: (widget.type == 'video' && _isRemoteUserJoined && _remoteUid != null)
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : _buildCallInfoPlaceholder(),
          ),

          // Local Preview (small)
          if (widget.type == 'video' && _isJoined && !_isVideoOff)
            Positioned(
              top: 60,
              right: 20,
              child: Container(
                width: 120,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // Call Controls Overlay
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (!_isRemoteUserJoined)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Text(
                      'Calling...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: _isMuted ? Colors.white.withOpacity(0.2) : Colors.white10,
                      iconColor: Colors.white,
                      onTap: _onToggleMute,
                    ),
                    const SizedBox(width: 20),
                    if (widget.type == 'video') ...[
                      _buildControlButton(
                        icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                        color: _isVideoOff ? Colors.white.withOpacity(0.2) : Colors.white10,
                        iconColor: Colors.white,
                        onTap: _onToggleVideo,
                      ),
                      const SizedBox(width: 20),
                      _buildControlButton(
                        icon: Icons.flip_camera_ios_rounded,
                        color: Colors.white10,
                        iconColor: Colors.white,
                        onTap: _onSwitchCamera,
                      ),
                      const SizedBox(width: 20),
                    ],
                    _buildControlButton(
                      icon: Icons.call_end_rounded,
                      color: AppColors.error,
                      iconColor: Colors.white,
                      onTap: _onEndCall,
                      size: 64,
                      iconSize: 32,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallInfoPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryStart.withOpacity(0.3), width: 4),
              image: widget.remoteUserAvatar != null && widget.remoteUserAvatar!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(AppConstants.getMediaUrl(widget.remoteUserAvatar)),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: widget.remoteUserAvatar == null || widget.remoteUserAvatar!.isEmpty
                  ? AppColors.primaryGradient
                  : null,
            ),
            child: widget.remoteUserAvatar == null || widget.remoteUserAvatar!.isEmpty
                ? Center(
                    child: Text(
                      widget.remoteUserName.isNotEmpty ? widget.remoteUserName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w900),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 30),
          Text(
            widget.remoteUserName,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            _isRemoteUserJoined ? 'Connected' : 'Ringing...',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    double size = 56,
    double iconSize = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
