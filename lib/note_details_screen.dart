import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'globals.dart';
import 'dart:collection';
import 'recording.dart';

class NoteDetailsScreen extends StatefulWidget {
  late int detailsIndex;
  final Function(String) onNoteTitleChanged;
  final Function(String) onNoteSummaryChanged;

  NoteDetailsScreen({
    required this.detailsIndex,
    required this.onNoteTitleChanged,
    required this.onNoteSummaryChanged,
  });

  @override
  _NoteDetailsScreenState createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  late TextEditingController _titleTextEditingController;
  late TextEditingController _summaryTextEditingController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleTextEditingController = TextEditingController(
        text: "${globalJsonData.keys.toList()[widget.detailsIndex]}");
    _summaryTextEditingController = TextEditingController(
        text:
            "${globalJsonData['${globalJsonData.keys.toList()[widget.detailsIndex]}']}");

    // Add a listener to the _summaryTextEditingController
    _summaryTextEditingController.addListener(() {
      // Call widget.onNoteTitleChanged with the new title whenever the controller's value changes
      widget.onNoteTitleChanged(_summaryTextEditingController.text);
      globalJsonData['${globalJsonData.keys.toList()[widget.detailsIndex]}'] =
          _summaryTextEditingController.text;
      putDataToAzureBlob();
    });
  }

  Future<void> putDataToAzureBlob() async {
    final Uri url = Uri.parse(
        'https://qossaysgstorage.blob.core.windows.net/summaries-file/${globalUsername}.json?sp=racwdl&st=2023-08-21T04:17:35Z&se=2023-10-01T12:17:35Z&sv=2022-11-02&sr=c&sig=FykibjXpJ9F0nHbdA7fG0N7WBIyGHJZUwtDdI628KMQ%3D');

    final headers = {
      "Content-Type": "application/json",
      "x-ms-blob-type": "BlockBlob"
    };

    final body = json.encode(globalJsonData);

    final response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 201) {
      print("Data put to Azure blob successfully.");
      Fluttertoast.showToast(
        msg: 'saved..',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    } else {
      print(
          "Failed to put data to Azure blob. Status code: ${response.statusCode}, Response body: ${response.body}");
    }
  }

  @override
  void dispose() {
    _titleTextEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
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
            border: Border.all(color: Colors.indigo),
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
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '${globalJsonData.keys.toList()[widget.detailsIndex]}',
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
                    border: Border.all(color: Colors.indigo),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  //the main text box
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _summaryTextEditingController,
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
                      backgroundColor: Colors.indigo,
                      onPressed: () {
                        _showTextBoxPopup(context);
                      },
                      child: Icon(Icons.text_fields),
                    ),
                    SizedBox(width: 46.0),
                    FloatingActionButton(
                      backgroundColor: Colors.indigo,
                      heroTag: "audio",
                      onPressed: () {
                        showRecorderPopup(context);
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

  //summarise function
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
              onPressed: () async {
                String text = textBoxController.text;
                // Update the API call to use the entered text
                await summarizeText(text);
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> getSummary(String operationLocation, String apiKey) async {
    try {
      final http.Response response = await http.get(
        Uri.parse(operationLocation),
        headers: {
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': apiKey
        },
      );

      if (response.statusCode == 200) {
        print('Success! Summary: ${response.body}');
        final Map<String, dynamic> responseBody = json.decode(response.body);
        final List<dynamic> tasks = responseBody['tasks']['items'];
        final Map<String, dynamic> task = tasks[0];
        final Map<String, dynamic> results = task['results'];
        final List<dynamic> documents = results['documents'];
        final Map<String, dynamic> document = documents[0];
        final List<dynamic> summaries = document['summaries'];
        final Map<String, dynamic> summary = summaries[0];
        final String summaryText = summary['text'];
        Fluttertoast.showToast(
          msg: 'getting your summary',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 7,
        );
        _summaryTextEditingController.text = summaryText;
      } else {
        print('Failed to get summary. Response: ${response.body}');
        Fluttertoast.showToast(
          msg: 'Failed to get summary. Please try again.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 7,
        );
      }
    } catch (e) {
      print('Error occurred: $e');
      Fluttertoast.showToast(
        msg: 'Error occurred: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    }
  }

  Future<void> summarizeText(String text) async {
    final String url =
        'https://sg-std-summarization.cognitiveservices.azure.com/language/analyze-text/jobs?api-version=2022-10-01-preview';
    final String apiKey = 'bfeba01a0beb4a00857143243bb4fa52';

    final Map<String, dynamic> requestBody = {
      'displayName': 'Document Abstractive Summarization Task Example',
      'analysisInput': {
        'documents': [
          {
            'id': '12',
            'language': 'en',
            'text': text, // Updated to use the entered text
          }
        ]
      },
      'tasks': [
        {
          'kind': 'AbstractiveSummarization',
          'taskName': 'Document Abstractive Summarization Task 1',
          'parameters': {'sentenceCount': 4}
        }
      ]
    };

    try {
      final http.Response response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': apiKey
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 202 || response.statusCode == 201) {
        print('Success! Response: ${response.body}');
        final String operationLocation =
            response.headers['operation-location'] ?? 'unknown';
        var duration = const Duration(seconds: 1);
        sleep(duration);
        await getSummary(operationLocation, apiKey);
      } else {
        print(
            'Failed with status code ${response.statusCode}. Response: ${response.body}');
        Fluttertoast.showToast(
          msg: 'Failed to post text. Please try again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
        );
      }
    } catch (e) {
      print('Error occurred: $e');
      Fluttertoast.showToast(
        msg: 'Error occurred: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    }
  }

Future<void> showRecorderPopup(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true, // user must tap outside to close!
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent, // Ensure dialog background is transparent
        child: SimpleRecorder(),
      );
    },
  );
}


  void _editNoteTitle() async {
    String currentTitle = globalJsonData.keys.toList()[widget.detailsIndex];
    TextEditingController titleController =
        TextEditingController(text: currentTitle);

    String newTitle = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Note Title'),
          content: TextField(
            controller: titleController,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context,
                    currentTitle); // Close the dialog and pass the current title
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String updatedTitle = titleController.text;

                Navigator.pop(context,
                    updatedTitle); // Close the dialog and pass the updated title
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (newTitle != null && newTitle != currentTitle) {
      setState(() {
        // Get the value associated with the currentTitle
        String value = globalJsonData[currentTitle];

        // Create a new LinkedHashMap and copy the original map to it
        LinkedHashMap<String, String> newMap = LinkedHashMap<String, String>();
        globalJsonData.forEach((key, val) {
          if (key == currentTitle) {
            // Add the newTitle with the associated value to the map
            newMap[newTitle] = value;
          } else {
            newMap[key] = val;
          }
        });

        // Update the globalJsonData with the newMap
        globalJsonData = newMap;
        widget.onNoteTitleChanged(newTitle);
        putDataToAzureBlob();
      });
    }
  }
}
