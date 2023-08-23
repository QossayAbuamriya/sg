import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';

class AudioRecording extends StatefulWidget {
  @override
  _AudioRecordingState createState() => _AudioRecordingState();
}

class _AudioRecordingState extends State<AudioRecording> {
  late FlutterSoundRecorder _recorder;
  bool _isRecording = false;
  int _fileNumber = 0;
  late Timer? _amplitudeChecker;
  int _recordedSeconds = 0;
  int _silencePeriods = 0;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _startRecording() async {
    _isRecording = true;
    while (_isRecording) {
      String path = "file${_fileNumber++}.mp3";
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.mp3,
      );
      _startAmplitudeChecking();

      await Future.delayed(Duration(seconds: 30));
      _stopAmplitudeChecking();

      await Future.delayed(Duration(seconds: 20));

      if (_isRecording) {
        await _recorder.stopRecorder();
      }
    }
  }

  void _startAmplitudeChecking() {
    _amplitudeChecker = Timer.periodic(Duration(seconds: 1), (timer) async {
      String? ampUrl = await _recorder.getRecordURL(path: "some_path_here"); // NOTE: this is likely incorrect and you should find a method to get the amplitude.
      _recordedSeconds++;

      if (ampUrl == null || ampUrl.length < SOME_THRESHOLD) { // NOTE: This condition is a placeholder, you need to replace this with actual amplitude check.
        _silencePeriods++;
      } else {
        _silencePeriods = 0;
      }

      if (_recordedSeconds >= 30 && _silencePeriods > 0) {
        _stopRecordingSegment();
      }
    });
  }

  void _stopAmplitudeChecking() {
    if (_amplitudeChecker != null) {
      _amplitudeChecker?.cancel();
      _amplitudeChecker = null;
    }
  }

  Future<void> _stopRecordingSegment() async {
    _stopAmplitudeChecking();
    _recordedSeconds = 0;
    _silencePeriods = 0;
    await _recorder.stopRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Audio Recording")),
      body: Center(
        child: ElevatedButton(
          child: Text(_isRecording ? "Stop Recording" : "Start Recording"),
          onPressed: _isRecording
              ? () async {
                  _isRecording = false;
                  await _stopRecordingSegment();
                }
              : _startRecording,
        ),
      ),
    );
  }
}

const double SOME_THRESHOLD = 0.02;  // Adjust based on testing
