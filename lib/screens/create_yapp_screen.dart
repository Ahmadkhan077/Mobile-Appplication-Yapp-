import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import '../database/databasesql.dart';
import 'yapp_list_screen.dart';
import 'videoplayerscreen.dart';


class CreateYappScreen extends StatefulWidget {
  const CreateYappScreen({Key? key}) : super(key: key);

  @override
  State<CreateYappScreen> createState() => _CreateYappScreenState();
}

class _CreateYappScreenState extends State<CreateYappScreen> {
  // Properties
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _timer;
  int _recordingSeconds = 0;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _showRecordingControls = false;
  String _formattedTime = "00:00";
  String? _recordingPath;
  File? _selectedImage;
  String? _videoPath;
  bool _isProcessing = false;
  VideoPlayerController? _videoPlayerController;

  // Group 1: Image Selection Functions

  /// Removes the selected picture and re-enables the picture button.
  void _removePicture() {
    setState(() {
      _selectedImage = null;
    });
  }


  /// Displays a bottom sheet to allow the user to select an image
  /// either from the camera or gallery. Updates `_selectedImage` state.
  /// Handles picture selection or capture and updates state accordingly.
  Future<void> _selectOrTakePicture() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Picture'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image =
                await _imagePicker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Select from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image =
                await _imagePicker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Group 2: Audio Recording Functions

  /// Starts the recording process using the `AudioRecorder`.
  /// Saves the audio file path in `_recordingPath`.
  /// initializes the timer for 2-minute tracking.
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final String path = p.join(directory.path,
            "recording_${DateTime.now().millisecondsSinceEpoch}.m4a");

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _showRecordingControls = true;
          _isPaused = false;
          _recordingPath = path;
          _startTimer(); // Start the timer to enforce the 2-minute limit
        });
      }
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  /// Toggles between pause and resume states for the recording.
  Future<void> _pauseOrResumeRecording() async {
    try {
      if (_isPaused) {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: _recordingPath!,
        );
        _startTimer();
      } else {
        await _audioRecorder.pause();
        _timer?.cancel();
      }
      setState(() {
        _isPaused = !_isPaused;
      });
    } catch (e) {
      print("Error pausing/resuming recording: $e");
    }
  }

  /// Removes the uploaded audio and re-enables the record button.
  void _removeAudio() {
    setState(() {
      _recordingPath = null;
    });
  }

  /// Stops the recording and resets the timer and state.
  /// Stops recording, resets the timer, and updates state with the audio path.
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _timer?.cancel();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _showRecordingControls = false;
        _recordingSeconds = 0;
        _formattedTime = "00:00";
        _recordingPath = path; // Keep track of the saved path
      });
      print("Recording saved at: $path");
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }



  /// Starts a timer to track recording duration and stops recording after 2 minutes.
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _recordingSeconds++;
        _formattedTime =
        "${(_recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}";
      });

      if (_recordingSeconds >= 120) { // Stop recording after 2 minutes
        _timer?.cancel();
        _stopRecording(); // Automatically stop the recording
      }
    });
  }


  // Group 3: Yapp Creation and Video Playback

  /// Combines the selected image and recorded audio into a video file (Yapp).
  /// Saves the video at `_videoPath`.
  /// Combines the selected image and recorded or picked audio into a video file (Yapp).
  /// Uses the `_recordingPath` as the background audio.
  Future<void> _createYapp() async {
    if (_selectedImage == null || _recordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image and upload audio')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final String outputPath = p.join(
          directory.path, "yapp_${DateTime.now().millisecondsSinceEpoch}.mp4");

      final String command =
          "-loop 1 -i ${_selectedImage!.path} -i $_recordingPath -c:v libx264 -preset ultrafast -tune stillimage -c:a aac -b:a 128k -shortest $outputPath";

      await FFmpegKit.executeAsync(command, (session) async {
        final returnCode = await session.getReturnCode();
        if (returnCode != null && returnCode.isValueSuccess()) {
          setState(() {
            _videoPath = outputPath;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yapp created successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create Yapp')),
          );
        }
        setState(() {
          _isProcessing = false;
        });
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      print("Error creating Yapp: $e");
    }
  }



  // Lifecycle Management
  @override
  void dispose() {
    _timer?.cancel();
    _videoPlayerController?.dispose();
    super.dispose();
  }


  // pick audio -------------------

  /// Allows the user to pick an audio file from the file system.
  /// Validates the audio duration (must be <= 2 minutes).
  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);

        // Validate audio duration
        final audioDuration = await _getAudioDuration(pickedFile);
        if (audioDuration > const Duration(minutes: 2)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio must be less than 2 minutes')),
          );
          return;
        }

        setState(() {
          _recordingPath = pickedFile.path; // Set the path of picked audio
          _formattedTime =
          "${audioDuration.inMinutes.toString().padLeft(2, '0')}:${(audioDuration.inSeconds % 60).toString().padLeft(2, '0')}";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio uploaded successfully!')),
        );
      }
    } catch (e) {
      print("Error picking audio: $e");
    }
  }

  /// Retrieves the duration of an audio file.
  /// [audioFile] is the file to check.
  /// Retrieves the duration of an audio file using FFprobeKit.
  /// [audioFile] is the file to check.
  /// Retrieves the duration of an audio file using FFprobeKit.
  /// [audioFile] is the file to check.
  Future<Duration> _getAudioDuration(File audioFile) async {
    try {
      final session = await FFprobeKit.getMediaInformation(audioFile.path);
      final mediaInformation = session.getMediaInformation(); // Get media info

      if (mediaInformation != null) {
        final durationStr = mediaInformation.getDuration(); // Get duration as a string
        if (durationStr != null) {
          final durationInSeconds = double.tryParse(durationStr) ?? 0;
          return Duration(seconds: durationInSeconds.toInt());
        }
      }

      // If duration is unavailable, return zero
      return const Duration(seconds: 0);
    } catch (e) {
      print("Error getting audio duration: $e");
      return const Duration(seconds: 0);
    }
  }


//save Yapp ----------------------------------------------------?>

  Future<void> _saveYapp() async {
    if (_selectedImage == null || _recordingPath == null || _videoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the Yapp before saving!')),
      );
      return;
    }

    try {
      final database = await YappDatabase.instance.database;

      // Insert into database
      await database.insert('yapps', {
        'name': 'Yapp#${DateTime.now().millisecondsSinceEpoch}', // Generate default name
        'imagePath': _selectedImage!.path,
        'audioPath': _recordingPath!,
        'videoPath': _videoPath!,
        'creationDate': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yapp saved successfully!')),
      );

      // Navigate to Yapp List Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const YappListScreen()),
      );
    } catch (e) {
      print('Error saving Yapp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save the Yapp.')),
      );
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Create Yapp',
          style: TextStyle(color: Colors.amber), // Golden text
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD3D3D3), Color(0xFF808080)], // Ash gray gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Picture Upload Section
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[200], // Lighter golden
                  foregroundColor: Colors.grey[900], // Text color
                ),
                onPressed: _selectedImage == null ? _selectOrTakePicture : null,
                child: const Text('Select/Take Picture'),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Picture uploaded",
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                    IconButton(
                      onPressed: _removePicture,
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Audio Recording and Picking Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[200], // Lighter golden
                        foregroundColor: Colors.grey[900],
                      ),
                      onPressed: _recordingPath == null ? _startRecording : null,
                      child: const Text('Start Recording'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[200], // Lighter golden
                        foregroundColor: Colors.grey[900],
                      ),
                      onPressed: _recordingPath == null ? _pickAudio : null,
                      child: const Text('Pick Audio'),
                    ),
                  ),
                ],
              ),
              if (_showRecordingControls) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300), // Smooth transition
                      child: FloatingActionButton.extended(
                        key: ValueKey<bool>(_isPaused),
                        onPressed: _pauseOrResumeRecording,
                        label: Text(_isPaused ? 'Start' : 'Pause'),
                        icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                        backgroundColor: Colors.amber[600], // Dynamic golden
                      ),
                    ),
                    FloatingActionButton.extended(
                      onPressed: _stopRecording,
                      label: const Text('Stop'),
                      icon: const Icon(Icons.stop),
                      backgroundColor: Colors.amber[600], // Dynamic golden
                    ),
                    Text(
                      _formattedTime,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700], // Light golden
                      ),
                    ),
                  ],
                ),
              ],
              if (_recordingPath != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Audio uploaded ($_formattedTime)",
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                    IconButton(
                      onPressed: _removeAudio,
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Yapp Creation Section
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[400], // Mid golden
                  foregroundColor: Colors.grey[900],
                ),
                onPressed: _isProcessing ? null : _createYapp,
                child: _isProcessing
                    ? const CircularProgressIndicator()
                    : const Text('Create Yapp'),
              ),

              // Video Playback and Save Section
              if (_videoPath != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600], // Darker golden
                        foregroundColor: Colors.grey[900],
                      ),
                      onPressed: () {
                        if (_videoPath != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                videoPath: _videoPath!,
                                yappPaths: [_videoPath!], // Single video as a list
                                currentIndex: 0, // Index is 0 since it's the only video
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No Yapp created to play.')),
                          );
                        }
                      },
                      child: const Text('Play Yapp'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600], // Darker golden
                        foregroundColor: Colors.grey[900],
                      ),
                      onPressed: _saveYapp,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}
