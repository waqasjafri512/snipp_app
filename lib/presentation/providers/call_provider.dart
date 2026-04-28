import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/socket_service.dart';
import '../screens/call_screen.dart';
import '../../main.dart';
import '../../core/constants/app_constants.dart';

class CallProvider with ChangeNotifier {
  StreamSubscription? _socketSub;
  bool _isCallActive = false;

  CallProvider() {
    _initSocketListener();
  }

  void _initSocketListener() {
    _socketSub?.cancel();
    _socketSub = SocketService().eventStream.listen((event) {
      if (event['event'] == 'incomingCall') {
        _handleIncomingCall(event['data']);
      }
    });
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    if (_isCallActive) {
      // Busy, reject or ignore
      return;
    }

    final context = MyApp.navigatorKey.currentContext;
    if (context == null) return;

    final int fromId = data['from'];
    final String fromName = data['fromName'];
    final String? fromAvatar = data['fromAvatar'];
    final String type = data['type'];
    final String channelName = data['channelName'];

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Incoming Call...',
                  style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryStart.withOpacity(0.5), width: 4),
                    image: fromAvatar != null && fromAvatar.isNotEmpty
                        ? DecorationImage(image: NetworkImage(AppConstants.getMediaUrl(fromAvatar)), fit: BoxFit.cover)
                        : null,
                    gradient: fromAvatar == null || fromAvatar.isEmpty ? AppColors.primaryGradient : null,
                  ),
                  child: fromAvatar == null || fromAvatar.isEmpty
                      ? Center(
                          child: Text(
                            fromName.isNotEmpty ? fromName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w900),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 30),
                Text(
                  fromName,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  '${type[0].toUpperCase()}${type.substring(1)} Call',
                  style: const TextStyle(color: AppColors.primaryStart, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallAction(
                      icon: Icons.close_rounded,
                      color: AppColors.error,
                      label: 'Decline',
                      onTap: () {
                        SocketService().emit('rejectCall', {'to': fromId});
                        Navigator.pop(context);
                      },
                    ),
                    _buildCallAction(
                      icon: type == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
                      color: AppColors.success,
                      label: 'Accept',
                      onTap: () {
                        _isCallActive = true;
                        SocketService().emit('answerCall', {'to': fromId, 'channelName': channelName});
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CallScreen(
                              remoteUserId: fromId,
                              remoteUserName: fromName,
                              remoteUserAvatar: fromAvatar,
                              type: type,
                              channelName: channelName,
                              isIncoming: true,
                            ),
                          ),
                        ).then((_) => _isCallActive = false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallAction({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
            ]),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}
