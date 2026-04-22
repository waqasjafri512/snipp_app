import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import '../providers/live_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import 'dart:ui';

class BroadcasterScreen extends StatefulWidget {
  final String channelName;
  final String title;

  const BroadcasterScreen({
    super.key,
    required this.channelName,
    required this.title,
  });

  @override
  State<BroadcasterScreen> createState() => _BroadcasterScreenState();
}

class _BroadcasterScreenState extends State<BroadcasterScreen> {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isLive = false;
  int? _localUid;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    final liveProv = Provider.of<LiveProvider>(context, listen: false);
    
    final hasPermission = await liveProv.handlePermissions();
    if (!hasPermission) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final tokenData = await liveProv.getAgoraToken(widget.channelName);
    if (tokenData == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final appId = tokenData['appId'];
    final token = tokenData['token'];
    _localUid = tokenData['uid'];

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isJoined = true);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          setState(() => _isJoined = false);
        },
      ),
    );

    await _engine!.enableVideo();
    await _engine!.startPreview();

    await _engine!.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: _localUid!,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );

    await liveProv.startStream(widget.channelName, widget.title);
    setState(() => _isLive = true);
  }

  Future<void> _onEnd() async {
    final liveProv = Provider.of<LiveProvider>(context, listen: false);
    await liveProv.endStream(widget.channelName);
    
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video View
          Positioned.fill(
            child: _isJoined
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: AppColors.primaryStart)),
          ),

          // Header Overlay
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF006E), Color(0xFFFB5607)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF006E).withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sensors_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: Colors.black.withOpacity(0.3),
                          child: const Row(
                            children: [
                              Icon(Icons.visibility_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('1.2K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _onEnd,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        color: Colors.black.withOpacity(0.3),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer Overlay
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 24, 
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassIconButton(Icons.flip_camera_ios_rounded, () => _engine?.switchCamera()),
                    _buildGlassIconButton(Icons.mic_rounded, () {}),
                    _buildGlassIconButton(Icons.face_retouching_natural_rounded, () {}),
                    _buildGlassIconButton(Icons.more_horiz_rounded, () {}),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryStart.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Dares',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
