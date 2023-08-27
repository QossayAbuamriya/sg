import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart'
    as p; // You might need this for path manipulation
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sg/globals.dart';
typedef _Fn = void Function();

const theSource = AudioSource.microphone;

class SimpleRecorder extends StatefulWidget {
  @override
  _SimpleRecorderState createState() => _SimpleRecorderState();
}

class _SimpleRecorderState extends State<SimpleRecorder> {
  Codec _codec = Codec.pcm16WAV;
  String _mPath = 'myRecord.wav';
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mRecorderIsInited = false;
  String pathh = '';
  int i = 0;

  @override
  void initState() {
    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
    super.initState();
  }


 Future<void> _sendAudioToServer(String filePath) async {
  final apiUrl = "https://summarygenius.pythonanywhere.com/api/upload";
  var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
  request.files.add(await http.MultipartFile.fromPath('file', filePath));

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData.containsKey("DisplayText")) {
        print(jsonData["DisplayText"]);
        recordedAudioResults.value = jsonData["DisplayText"];
        Fluttertoast.showToast(
          msg: jsonData["DisplayText"],
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
        );
      } else {
        print("DisplayText key not found in the response.");
      }
    } else {
      print("Request failed with status: ${response.statusCode}.");
      print(response.body);
      Fluttertoast.showToast(
        msg: "Error: ${response.body}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    }
  } catch (e) {
    print("Error while sending request to Flask API: $e");
  }
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
    final documents =
        p.join(directory!.parent.parent.parent.parent.path, "Documents");
    return p.join(documents, 'myRecord${i}.wav'); // or .webm based on codec
  }

  void record() async {
    i++;
    String path = await getFilePath();
    pathh = path;
    print(pathh);
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

  void stopRecorder() async {
    await _mRecorder!.stopRecorder().then((value) {
      _sendAudioToServer(pathh);

      Navigator.of(context).pop(_mPath); // Return the recorded file path
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
        child: Column(
          mainAxisSize: MainAxisSize.min, // To avoid unnecessary expansion
          children: [
            Row(
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
            SizedBox(height: 10), // Provides spacing
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType
                      .audio, // Ensure that only audio files can be selected
                );
                if (result != null) {
                  PlatformFile file = result.files.first;
                  print(file.name); // Name of the picked file
                  print(file.path); // Path of the picked file

                  if (file.path != null) {
                    await _sendAudioToServer(file.path!);
                  }
                }
              },
              child: Text('FilePicker'),
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

  // @override
  // Widget build(BuildContext context) {
  //   Widget recorderBody() {
  //     return Container(
  //       margin: const EdgeInsets.symmetric(vertical: 10),
  //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //       decoration: BoxDecoration(
  //         color: Color(0xFFFAF0E6),
  //         borderRadius: BorderRadius.circular(20),
  //         border: Border.all(
  //           color: Colors.indigo,
  //           width: 2,
  //         ),
  //       ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: [
  //           ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               primary: Colors.indigo,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //             ),
  //             onPressed: getRecorderFn(),
  //             child: Text(_mRecorder!.isRecording ? 'Stop' : 'Record'),
  //           ),
  //           Text(
  //             _mRecorder!.isRecording ? 'Recording' : 'Ready',
  //             style: TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: _mRecorder!.isRecording ? Colors.red : Colors.green,
  //             ),
  //           ),
  //         ],
  //       ),

  //     );
  //   }

  //   Future<void> _showRecorderPopup() async {
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return Dialog(
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(20),
  //           ),

  //           child: Padding(
  //             padding: const EdgeInsets.all(20),

  //             child: recorderBody(),
  //           ),
  //         );
  //       },
  //     );
  //   }

  //   // Call the function immediately
  //   WidgetsBinding.instance?.addPostFrameCallback((_) {
  //     _showRecorderPopup();
  //   });

  //   // Return an empty Scaffold (since we're using a dialog for content display)
  //   return SizedBox.shrink();
  // }
}
