import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

class VideoFeedPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  const VideoFeedPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
  });

  @override
  State<VideoFeedPlayer> createState() => _VideoFeedPlayerState();
}

class _VideoFeedPlayerState extends State<VideoFeedPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = true;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Get cached video file or download it via flutter_cache_manager
      final fileInfo = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      
      if (!mounted) return;

      // 2. Initialize VideoPlayerController with the local cached file
      _controller = VideoPlayerController.file(File(fileInfo.path))
        ..setLooping(true)
        ..setVolume(_isMuted ? 0.0 : 1.0);

      await _controller!.initialize();
      
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      if (widget.autoPlay) {
        _controller!.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load video';
        });
      }
      print('Video player init error: $e');
    }
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  void didUpdateWidget(covariant VideoFeedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _initializePlayer();
    } else if (_isInitialized && _controller != null) {
      if (widget.autoPlay && !_controller!.value.isPlaying) {
        _controller!.play();
      } else if (!widget.autoPlay && _controller!.value.isPlaying) {
        _controller!.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        color: Colors.black12,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 300,
        color: Colors.black12,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.grey, size: 40),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Video Frame
            VideoPlayer(_controller!),

            // Mute / Unmute Button (Top Right)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            // Play / Pause Overlay Indicator
            if (!_controller!.value.isPlaying)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),

            // Progress Bar / Scrub
            VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.pink,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
