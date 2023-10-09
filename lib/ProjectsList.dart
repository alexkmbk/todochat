import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/src/response.dart';
import 'HttpClient.dart';
import 'customWidgets.dart';
import 'utils.dart';
import 'main_menu.dart';
import 'LoginPage.dart';

import 'todochat.dart';
import 'dart:convert';
import 'package:collection/collection.dart';

class Project {
  int ID = 0;
  String Description = "";
  bool editMode = false;
  bool isNewItem = false;

  Project(
      {this.ID = 0,
      this.Description = "",
      this.editMode = false,
      this.isNewItem = false});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'Description': Description,
    };
  }

  Project.fromJson(Map<String, dynamic> json)
      : ID = json['ID'],
        Description = json['Description'];

  Project.from(Project project)
      : ID = project.ID,
        Description = project.Description;
}

class ProjectsPage extends StatefulWidget {
  ProjectsPage({Key? key}) : super(key: key);

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final ScrollController _scrollController = ScrollController();
  List<Project> items = [];
  bool loading = false;

  //final _projetcInputController = TextEditingController();
  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!loading &&
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
          title: const TextField(
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
          leading: const MainMenu(),
          actions: [
            IconButton(
              onPressed: () {
                addEditorItem();
              },
              icon: const Icon(
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
                return buildListRow(context, index, items[index]);
                /*if (index < _taskListProvider.items.length) {
            return buildListRow(context, index, _taskListProvider.items[index],
                _taskListProvider, widget);
          }
          return const Center(child: Text('End of list'));*/
              },
              itemCount: items.length,
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
                        if (project.isNewItem) {
                          deleteEditorItem();
                        } else {
                          setState(() {
                            project.editMode = false;
                          });
                        }
                      }
                    },
                    child: TextField(
                      controller: TextEditingController()
                        ..text = project.Description,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              (project.isNewItem) ? "New project name" : null),
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) async {
                        if (value.isNotEmpty) {
                          if (project.isNewItem) {
                            await createProject(value);
                            deleteEditorItem();
                          } else {
                            var tempProject = Project.from(project);
                            tempProject.Description = value;
                            var res = await updateProject(tempProject);
                            if (res) {
                              setState(() {
                                project.Description = tempProject.Description;
                                project.editMode = false;
                              });
                            }
                          }
                        }
                      },
                    ),
                  ))));
    } else {
      return Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (direction) {
            return confirmDismissDlg(context);
          },
          onDismissed: (direction) async {
            await deleteProject(project.ID);
          },
          child: ListTile(
            shape: const Border(bottom: BorderSide(color: Colors.grey)),
            onTap: () => onTap(project),
            onLongPress: () => onLongPress(project),
            title: Text(project.Description),
            trailing: const Icon(Icons.keyboard_arrow_right),
          ));
    }
  }

  void addEditorItem() {
    setState(() {
      items.insert(0, Project(editMode: true, isNewItem: true));
    });
  }

  void deleteEditorItem() {
    setState(() {
      items.removeWhere((item) => item.editMode == true);
    });
  }

  Future<Project?> createProject(String Description) async {
    if (sessionID == "") {
      return null;
    }

    Project project = Project(Description: Description);

    Response response;
    try {
      response = await httpClient.post(
          setUriProperty(serverURI, path: 'createProject'),
          body: jsonEncode(project));
    } catch (e) {
      return null;
    }

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      project.ID = data["ID"];
      setState(() {
        items.insert(0, project);
      });
      return project;
    }

    return null;
  }

  Future<bool> updateProject(Project project) async {
    if (sessionID == "") {
      return false;
    }

    Response response;
    try {
      response = await httpClient.post(
          setUriProperty(serverURI, path: 'updateProject'),
          body: jsonEncode(project));
    } catch (e) {
      return false;
    }

    if (response.statusCode == 200) {
      return true;
    } else {
      toast(response.body.toString(), context);
      return false;
    }
  }

  Future<void> onTap(Project project) async {
    Navigator.pop(context, project);
  }

  Future<void> onLongPress(Project project) async {
    setState(() {
      var foundProject =
          items.firstWhereOrNull((element) => element.ID == project.ID);
      if (foundProject != null) {
        foundProject.editMode = true;
        foundProject.isNewItem = false;
      }
    });
  }

  Future<bool> deleteProject(int projectID) async {
    if (sessionID == "") {
      return false;
    }
    Response response;

    try {
      response = await httpClient
          .delete(setUriProperty(serverURI, path: 'deleteProject/$projectID'));
    } catch (e) {
      return false;
    }

    if (response.statusCode == 200) {
      setState(() {
        items.removeWhere((item) => item.ID == projectID);
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

    loading = true;

    Response response;
    try {
      response =
          await httpClient.get(setUriProperty(serverURI, path: 'projects'));
    } catch (e) {
      return;
    }

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      var items = data["items"];

      if (items == null) {
        loading = false;
        return;
      }

      for (var item in items) {
        res.add(Project(Description: item["Description"], ID: item["ID"]));
      }
    } else if (response.statusCode == 401) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    loading = false;

    items = [...items, ...res];
    if (mounted) {
      setState(() => {});
    }
  }

  /*void _scrollDown() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _scrollUp() {
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }*/
}

Future<Project?> requestFirstItem() async {
  if (sessionID == "") {
    return null;
  }
  Response response;
  try {
    response = await httpClient.get(setUriProperty(serverURI, path: 'projects'),
        headers: {"limit": "1"});
  } catch (e) {
    return null;
  }

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);

    var items = data["items"];

    if (items == null || items.length == 0) {
      return null;
    }
    return Project.fromJson(items[0]);
  }
  return null;
}

Future<Project?> getProject(int? projectID) async {
  if (sessionID == "") {
    return null;
  }

  Response response;
  try {
    response = await httpClient
        .get(setUriProperty(serverURI, path: 'project/$projectID'));
  } catch (e) {
    return null;
  }

  if (response.statusCode == 200) {
    return Project.fromJson(jsonDecode(response.body));
  }

  return null;
}
