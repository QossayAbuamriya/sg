import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class NoteDetailsScreen extends StatefulWidget {
  late String noteTitle;
  final Function(String) onNoteTitleChanged;

  NoteDetailsScreen({
    required this.noteTitle,
    required this.onNoteTitleChanged,
  });

  @override
  _NoteDetailsScreenState createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  late TextEditingController _textEditingController;
  final FocusNode _focusNode = FocusNode();

  bool _isRecording = false;
  late Record _record;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.noteTitle);
    _record = Record();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final appDocumentsDirectory = await getApplicationDocumentsDirectory();
        final fileName = DateTime.now().toIso8601String();
        final filePath = '${appDocumentsDirectory.path}/$fileName';
        await _record.start(path: filePath);
        setState(() {
          _isRecording = true;
          _audioFilePath = filePath;
        });
      } else {
        print('No permission to record audio.');
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _record.stop();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note Details'),
      ),
      resizeToAvoidBottomInset:
          false, // Prevents the keyboard from pushing the content
      body: GestureDetector(
        onTap: () {
          // Unfocus the text field when tapping outside of it
          _focusNode.unfocus();
        },
        child: Container(
          margin: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.lightBlueAccent),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 131, 148, 157).withOpacity(0.3),
                blurRadius: 4.0,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 11.0,
                left: 11.0,
                child: GestureDetector(
                  onTap: _editNoteTitle,
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 100, 118, 127),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      widget.noteTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8.0,
                right: 8.0,
                bottom: 623.0,
                child: Container(
                  height: 2.0,
                  color: Color.fromARGB(255, 101, 126, 137),
                ),
              ),
              Positioned(
                left: 8.0,
                right: 8.0,
                bottom: 8.0,
                child: Container(
                  height: MediaQuery.of(context).size.height -
                      200, // Adjust the height as needed
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.lightBlueAccent),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _textEditingController,
                      focusNode: _focusNode,
                      maxLines:
                          null, // Allows the text field to grow dynamically
                      style: TextStyle(
                        color: const Color.fromARGB(255, 18, 18, 18),
                        fontSize: 16.0,
                      ),
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter your note here',
                        hintStyle: TextStyle(
                          color: const Color.fromARGB(255, 39, 39, 39)
                              .withOpacity(0.5),
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16.0,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        _showTextBoxPopup(context);
                      },
                      child: Icon(Icons.text_fields),
                    ),
                    SizedBox(width: 46.0),
                    FloatingActionButton(
                      heroTag: "audio",
                      onPressed: () {
                        _showAudioRecordingPopup(context);
                      },
                      child: Icon(Icons.volume_up),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextBoxPopup(BuildContext context) {
    TextEditingController textBoxController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Text'),
          content: TextField(
            controller: textBoxController,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String text = textBoxController.text;
                // Do something with the entered text
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAudioRecordingPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Audio Recording',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              Text('Place your audio recording widget here'),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editNoteTitle() async {
    String? updatedTitle = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Note Title'),
          content: TextField(
            controller: _textEditingController,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context); // Close the dialog without saving changes
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String updatedTitle = _textEditingController.text;
                widget.onNoteTitleChanged(
                    updatedTitle); // Update the note title in the main list
                Navigator.pop(context,
                    updatedTitle); // Close the dialog and pass the updated title
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (updatedTitle != null) {
      setState(() {
        widget.noteTitle =
            updatedTitle; // Update the note title in the current screen
      });
    }
  }
}
