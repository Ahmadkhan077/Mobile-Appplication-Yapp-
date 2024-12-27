import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final List<String> yappPaths; // List of all Yapp video paths
  final int currentIndex; // Current Yapp index in the list

  const VideoPlayerScreen({
    Key? key,
    required this.videoPath,
    required this.yappPaths,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _initializeVideo(widget.videoPath);
  }

  void _initializeVideo(String path) {
    _controller = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _playNextVideo() {
    if (_currentIndex < widget.yappPaths.length - 1) {
      setState(() {
        _currentIndex++;
        _controller.dispose();
        _initializeVideo(widget.yappPaths[_currentIndex]);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is the last Yapp!')),
      );
    }
  }

  void _playPreviousVideo() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _controller.dispose();
        _initializeVideo(widget.yappPaths[_currentIndex]);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is the first Yapp!')),
      );
    }
  }

  Future<void> _shareCurrentVideo() async {
    try {
      final currentPath = widget.yappPaths[_currentIndex];
      await Share.shareXFiles([XFile(currentPath)], text: 'Check out my Yapp!');
    } catch (e) {
      print('Error sharing video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Play Yapp',
          style: TextStyle(color: Colors.amber),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber[700]!, width: 2),
            ),
            child: IconButton(
              icon: Icon(Icons.share, color: Colors.amber[700]),
              onPressed: _shareCurrentVideo,
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _togglePlayPause,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) {
              _playPreviousVideo(); // Swipe right
            } else if (details.primaryVelocity! < 0) {
              _playNextVideo(); // Swipe left
            }
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD3D3D3), Color(0xFF808080)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
                : const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
