import 'package:flutter/material.dart';
import 'note_details_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'globals.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> globalJsonData = {};
  List<int> widgetList = [];
  List<String> noteTitles = [];
  
  
  String username = globalUsername;

  @override
  void initState() {
    super.initState();
    fetchAndSetGlobalData();
  }

  void setGlobalJsonData(String jsonString) {
    setState(() {
      globalJsonData = jsonDecode(jsonString);
    });
  }
  

  Future<void> fetchAndSetGlobalData() async {
    final Uri url = Uri.parse(
        'https://qossaysgstorage.blob.core.windows.net/summaries-file/${username}.json?sp=racwdl&st=2023-08-21T04:17:35Z&se=2023-10-01T12:17:35Z&sv=2022-11-02&sr=c&sig=FykibjXpJ9F0nHbdA7fG0N7WBIyGHJZUwtDdI628KMQ%3D');

    try {
      final http.Response response = await http.get(url);
      if (response.statusCode == 200) {
        setGlobalJsonData(response.body);
        print('Global JSON data set successfully');
      } else {
        print(
            'Error fetching data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error making API call: $e');
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Stack(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
            child: ListView.builder(
              itemCount: globalJsonData.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    _navigateToNoteDetailsScreen(context, index);
                  },
                  child: Container(
                    margin:
                        EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: Colors.lightBlueAccent),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(255, 131, 148, 157)
                              .withOpacity(0.3),
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8.0,
                          left: 8.0,
                          child: Container(
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 100, 118, 127),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                _editNoteTitle(index);
                              },
                              child: Text(
                                globalJsonData.keys.toList()[index],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8.0,
                          right: 8.0,
                          bottom: 135.0,
                          child: Container(
                            height: 2.0,
                            color: Color.fromARGB(255, 101, 126, 137),
                          ),
                        ),
                        Positioned(
                          left: 8.0,
                          right: 8.0,
                          top: 50.0,
                          child: Container(
                            width: 300.0,
                            height: 100.0,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${globalJsonData["summary 3"]}',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 42, 60, 68),
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    height: 180.0,
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  int newItem = globalJsonData.length + 1;
                  widgetList.add(newItem);
                  noteTitles.add('Note Title');
                });
              },
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void _editNoteTitle(int index) async {
    String currentTitle = noteTitles[index];
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

    if (newTitle != null) {
      setState(() {
        noteTitles[index] = newTitle;
      });
    }
  }

  void _navigateToNoteDetailsScreen(BuildContext context, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailsScreen(
          noteTitle: noteTitles[index],
          onNoteTitleChanged: (updatedTitle) {
            _updateNoteTitle(
                index, updatedTitle); // Update the note title in the main list
          },
        ),
      ),
    );
  }

  void _updateNoteTitle(int index, String updatedTitle) {
    setState(() {
      noteTitles[index] = updatedTitle;
    });
  }
}
