import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils.dart';
import 'MainMenu.dart';
import 'LoginPage.dart';

import 'main.dart';
import 'dart:convert';

class Project {
  int ID = 0;
  String Description = "";
  bool editMode = false;

  Project({this.ID = 0, this.Description = "", this.editMode = false});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'Description': Description,
    };
  }

  Project.fromJson(Map<String, dynamic> json)
      : ID = json['ID'],
        Description = json['Description'];
}

class ProjectsPage extends StatefulWidget {
  List<Project> items = [];
  bool loading = false;

  ProjectsPage({Key? key}) : super(key: key);

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final ScrollController _scrollController = ScrollController();
  final _projetcInputController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!widget.loading &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent) {
        requestItems(context);
      }
    });

    requestItems(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          //title: Text("ToDo Chat"),
          title: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: TextStyle(color: Colors.white),
//                filled: true,
//                fillColor: Colors.white,
                border: InputBorder.none,
                suffixIcon: Icon(
                  Icons.search,
                ),
              )),
          leading: MainMenu(),
          actions: [
            IconButton(
              onPressed: () {
                addEditorItem();
              },
              icon: Icon(
                Icons.add,
                color: Colors.white,
              ),
              tooltip: "New project",
            )
          ],
        ),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(
                child: ListView.builder(
              controller: _scrollController,
              itemBuilder: (context, index) {
                return buildListRow(context, index, widget.items[index]);
                /*if (index < _taskListProvider.items.length) {
            return buildListRow(context, index, _taskListProvider.items[index],
                _taskListProvider, widget);
          }
          return const Center(child: Text('End of list'));*/
              },
              itemCount: widget.items.length,
            )),
          ]),
        ),
      ),
    );
  }

  Widget buildListRow(BuildContext context, int index, Project project) {
    if (project.editMode) {
      return Container(
          //margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: 1,
            ),
            //borderRadius: BorderRadius.circular(10)
          ),
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.escape,
                        control: false): () {
                      FocusScope.of(context).unfocus();
                    },
                  },
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        deleteEditorItem();
                      }
                    },
                    child: TextField(
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "New project name"),
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) async {
                        if (!value.isEmpty) {
                          await createProject(value);
                          deleteEditorItem();
                        }
                      },
                    ),
                  ))));
    } else {
      return Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (direction) {
            return confirmDimissDlg(
                "Are you sure you wish to delete this item?", context);
          },
          onDismissed: (direction) async {
            await deleteProject(project.ID);
          },
          child: ListTile(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey),
            ),
            onTap: () => onTap(project),
            dense: true,
            minVerticalPadding: 0,
            minLeadingWidth: 0,
            contentPadding: EdgeInsets.zero,
            //contentPadding: EdgeInsets.only(bottom: 0.0, top: 0.0),
            title: Text(project.Description),
            trailing: Icon(Icons.keyboard_arrow_right),
          )
          /* Container(
            //margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
              //borderRadius: BorderRadius.circular(10)
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.black, width: 1), borderRadius: BorderRadius.circular(5)),
              onTap: () => onTap(project),
              dense: true,
              title: Text(project.Description),
              trailing: Icon(Icons.keyboard_arrow_right),
            ),
          )*/
          );
    }
  }

  void addEditorItem() {
    setState(() {
      widget.items.insert(0, Project(editMode: true));
    });
  }

  void deleteEditorItem() {
    setState(() {
      widget.items.removeWhere((item) => item.editMode == true);
    });
  }

  Future<Project?> createProject(String Description) async {
    if (sessionID == "") {
      return null;
    }

    Project project = Project(Description: Description);
    String body = jsonEncode(project);

    Map<String, String> headers = Map<String, String>();
    headers["sessionID"] = sessionID;
    headers["content-type"] = "application/json; charset=utf-8";

    var response;
    try {
      response = await httpClient.post(Uri.http(server, '/createProject'),
          body: body, headers: headers);
    } catch (e) {
      return null;
    }

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      project.ID = data["ID"];
      setState(() {
        widget.items.insert(0, project);
      });
      return project;
    }

    return null;
  }

  Future<void> onTap(Project project) async {
    Navigator.pop(context, project);
  }

  Future<bool> deleteProject(int projectID) async {
    if (sessionID == "") {
      return false;
    }

    Map<String, String> headers = Map<String, String>();
    headers["sessionID"] = sessionID;

    var response;

    try {
      response = await httpClient.delete(
          Uri.http(server, '/deleteProject/' + projectID.toString()),
          headers: headers);
    } catch (e) {
      return false;
    }

    if (response.statusCode == 200) {
      setState(() {
        widget.items.removeWhere((item) => item.ID == projectID);
      });

      return true;
    }

    return false;
  }

  Future<void> requestItems(BuildContext context) async {
    List<Project> res = [];

    if (sessionID == "") {
      return;
    }

    Map<String, String> headers = Map<String, String>();
    headers["sessionID"] = sessionID;

    widget.loading = true;

    var response;
    try {
      response =
          await httpClient.get(Uri.http(server, '/projects'), headers: headers);
    } catch (e) {
      return;
    }

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      var items = data["items"];

      if (items == null) {
        widget.loading = false;
        return;
      }

      for (var item in items) {
        res.add(Project(Description: item["Description"], ID: item["ID"]));
      }
    } else if (response.statusCode == 401) {
      bool result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    widget.loading = false;

    setState(() => widget.items = [...widget.items, ...res]);
  }

  /*void _scrollDown() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _scrollUp() {
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }*/
}

Future<Project?> getProject(int? projectID) async {
  if (sessionID == "") {
    return null;
  }

  Map<String, String> headers = Map<String, String>();
  headers["sessionID"] = sessionID;

  var response;
  try {
    response = await httpClient.get(
        Uri.http(server, '/project/' + projectID.toString()),
        headers: headers);
  } catch (e) {
    return null;
  }

  if (response.statusCode == 200) {
    return Project.fromJson(jsonDecode(response.body));
  }

  return null;
}
