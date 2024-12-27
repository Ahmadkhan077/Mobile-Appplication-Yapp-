import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/yapp.dart';
import 'create_yapp_screen.dart';
import '../database/databasesql.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'videoplayerscreen.dart';

class YappListScreen extends StatefulWidget {
  const YappListScreen({Key? key}) : super(key: key);

  @override
  State<YappListScreen> createState() => _YappListScreenState();
}

class _YappListScreenState extends State<YappListScreen> {
  List<Yapp> _yapps = [];
  Set<String> _selectedYapps = {};
  bool _isEditing = false;
  Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _fetchYapps();
  }

  Future<void> _fetchYapps() async {
    final database = await YappDatabase.instance.database;
    final result = await database.query('yapps');

    setState(() {
      _yapps = result.map((e) {
        final yapp = Yapp(
          id: e['id'].toString(),
          name: e['name'] as String,
          imagePath: e['imagePath'] as String,
          audioPath: e['audioPath'] as String,
          videoPath: e['videoPath'] as String,
          creationDate: DateTime.parse(e['creationDate'] as String),
        );
        // Create a controller for each Yapp's name
        _controllers[yapp.id] = TextEditingController(text: yapp.name);
        return yapp;
      }).toList();
    });
  }

  Future<void> _shareYapp(String videoPath) async {
    try {
      await Share.shareXFiles([XFile(videoPath)], text: 'Check out my Yapp!');
    } catch (e) {
      print('Error sharing Yapp: $e');
    }
  }


  void _playYapp(BuildContext context, String videoPath) {
    final videoPaths = _yapps.map((yapp) => yapp.videoPath).toList();
    final currentIndex = videoPaths.indexOf(videoPath);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoPath: videoPath,
          yappPaths: videoPaths,
          currentIndex: currentIndex,
        ),
      ),
    );
  }




  Future<void> _downloadYapp(String videoPath) async {
    try {
      // Get the external storage directory
      final directory = Directory('/storage/emulated/0/Pictures/Yapps');

      // Create the "Yapps" folder inside the Pictures directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Generate the new path for the video in the "Yapps" folder
      final fileName = path.basename(videoPath);
      final newPath = path.join(directory.path, fileName);

      // Copy the video to the new location
      await File(videoPath).copy(newPath);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video saved to $newPath')),
      );
    } catch (e) {
      print('Error downloading Yapp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error occurred during download.')),
      );
    }
  }

  Future<void> _deleteYapps() async {
    final database = YappDatabase.instance;
    for (var id in _selectedYapps) {
      await database.deleteYapp(id);
    }

    setState(() {
      _yapps.removeWhere((yapp) => _selectedYapps.contains(yapp.id));
      _selectedYapps.clear();
    });
  }

  Future<void> _renameYapp(Yapp yapp, String newName) async {
    final database = YappDatabase.instance;
    await database.updateYappName(yapp.id, newName);

    setState(() {
      yapp.name = newName;
      _controllers[yapp.id]?.text = newName; // Update the controller
    });
  }

  String _formatElapsedTime(DateTime creationDate) {
    final now = DateTime.now();
    final difference = now.difference(creationDate);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}m';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          _selectedYapps.isNotEmpty
              ? '${_selectedYapps.length} selected'
              : 'Yapp List',
          style: TextStyle(
            color: Colors.amber[700], // Darker golden for AppBar text
          ),
        ),
        actions: _selectedYapps.isNotEmpty
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.amber[700], // Golden icon
            onPressed: _deleteYapps,
          ),
        ]
            : [],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD3D3D3), Color(0xFF808080)], // Ash gray gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _fetchYapps,
          child: ListView.builder(
            itemCount: _yapps.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700], // Golden button
                      foregroundColor: Colors.grey[900], // Text color
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateYappScreen(),
                        ),
                      );
                    },
                    child: const Text('Create a Yapp'),
                  ),
                );
              }
              final yapp = _yapps[index - 1];
              final isSelected = _selectedYapps.contains(yapp.id);

              return GestureDetector(
                onLongPress: () {
                  setState(() {
                    if (isSelected) {
                      _selectedYapps.remove(yapp.id);
                    } else {
                      _selectedYapps.add(yapp.id);
                    }
                  });
                },
                onTap: () {
                  if (_selectedYapps.isNotEmpty) {
                    setState(() {
                      if (isSelected) {
                        _selectedYapps.remove(yapp.id);
                      } else {
                        _selectedYapps.add(yapp.id);
                      }
                    });
                  }
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.amber[700]!, // Golden outline for card
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(yapp.imagePath),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: TextField(
                      controller: _controllers[yapp.id],
                      style: TextStyle(
                        color: Colors.amber[600], // Lighter golden for input
                        fontSize: 16,
                      ),
                      onSubmitted: (newName) {
                        _renameYapp(yapp, newName);
                      },
                    ),
                    subtitle: Text(
                      _formatElapsedTime(yapp.creationDate),
                      style: TextStyle(
                        color: Colors.amber[400], // Light golden for small text
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIconButton(Icons.play_arrow, () => _playYapp(context, yapp.videoPath)),
                        _buildIconButton(Icons.share, () => _shareYapp(yapp.videoPath)),
                        _buildIconButton(Icons.download, () => _downloadYapp(yapp.videoPath)),
                      ],
                    ),
                    tileColor: isSelected ? Colors.grey[700]!.withOpacity(0.2) : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.amber[700]!, width: 2), // Golden circular outline
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.amber[700]), // Golden icon
        onPressed: onPressed,
      ),
    );
  }

}
