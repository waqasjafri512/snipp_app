import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import '../providers/live_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import 'dart:ui';

class ViewerScreen extends StatefulWidget {
  final int broadcasterId;
  final String channelName;
  final String broadcasterName;

  const ViewerScreen({
    super.key,
    required this.broadcasterId,
    required this.channelName,
    required this.broadcasterName,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  RtcEngine? _engine;
  bool _isJoined = false;
  int? _localUid;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    final liveProv = Provider.of<LiveProvider>(context, listen: false);
    
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
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (remoteUid == widget.broadcasterId) {
            if (mounted) Navigator.pop(context);
          }
        },
      ),
    );

    await _engine!.enableVideo();

    await _engine!.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: _localUid!,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
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
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: widget.broadcasterId),
                      connection: RtcConnection(channelId: widget.channelName),
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
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                      color: Colors.black.withOpacity(0.3),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.broadcasterName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('Live', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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

          // Bottom Bar & Reactions
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Reactions List
                Column(
                  children: [
                    _buildReactionChip('🔥'),
                    _buildReactionChip('😱'),
                    _buildReactionChip('😂'),
                    _buildReactionChip('💯'),
                  ],
                ),
                const SizedBox(height: 20),
                // Input & Share
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: Colors.white.withOpacity(0.15),
                            child: const Text(
                              'Say something nice...',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildGlassIconButton(Icons.share_rounded),
                    const SizedBox(width: 12),
                    _buildGlassIconButton(Icons.favorite_rounded, color: const Color(0xFFFF006E)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionChip(String emoji) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 45,
            height: 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon, {Color color = Colors.white}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
