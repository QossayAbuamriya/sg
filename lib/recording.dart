import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // You might need this for path manipulation



typedef _Fn = void Function();

const theSource = AudioSource.microphone;

class SimpleRecorder extends StatefulWidget {
  @override
  _SimpleRecorderState createState() => _SimpleRecorderState();
}

class _SimpleRecorderState extends State<SimpleRecorder> {
  Codec _codec = Codec.pcm16WAV;
  String _mPath = 'myRecord.wav.wav';
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mRecorderIsInited = false;
  String  pathh = '';

  @override
  void initState() {
    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
    super.initState();
  }

  void stopRecorder() async {
    await _mRecorder!.stopRecorder().then((value) {
      Navigator.of(context).pop(_mPath); // Return the recorded file path
    });
  }

  @override
  void dispose() {
    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder!.openRecorder();
    if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
      _mPath = 'myRecord.wav.webm';
      if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
        _mRecorderIsInited = true;
        return;
      }
    }
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    _mRecorderIsInited = true;
  }

  Future<String> getFilePath() async {
  final directory = await getExternalStorageDirectory();
  final documents = p.join(directory!.parent.parent.parent.parent.path, "Documents");
  return p.join(documents, 'myRecord.wav'); // or .webm based on codec
}

  void record() async {
  String path = await getFilePath();

  _mRecorder!
      .startRecorder(
    toFile: path,
    codec: _codec,
    audioSource: theSource,
  )
      .then((value) {
    setState(() {});
  });
}

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited) {
      return null;
    }
    return _mRecorder!.isStopped ? record : stopRecorder;
  }

  @override
  Widget build(BuildContext context) {
    Widget recorderBody() {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFFFAF0E6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.indigo,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: getRecorderFn(),
              child: Text(_mRecorder!.isRecording ? 'Stop' : 'Record'),
            ),
            Text(
              _mRecorder!.isRecording ? 'Recording' : 'Ready',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _mRecorder!.isRecording ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    Future<void> _showRecorderPopup() async {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: recorderBody(),
            ),
          );
        },
      );
    }

    // Call the function immediately
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _showRecorderPopup();
    });

    // Return an empty Scaffold (since we're using a dialog for content display)
    return SizedBox.shrink();
  }
}
