import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/src/response.dart';
import 'package:todochat/models/project.dart';
import 'package:todochat/ui_components/confirm_detele_dlg.dart';
import 'HttpClient.dart';
import 'utils.dart';
import 'LoginRegistrationPage.dart';

import 'todochat.dart';
import 'dart:convert';
import 'package:collection/collection.dart';

class ProjectsPage extends StatefulWidget {
  final Project? currentItem;
  const ProjectsPage({Key? key, required this.currentItem}) : super(key: key);

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();

  static Future<Project?> choice(
      {required BuildContext context, Project? currentItem}) async {
    return await showDialog<Project>(
        context: context,
        builder: (BuildContext context) {
          return ProjectsPage(
            currentItem: currentItem,
          );
        });
  }
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
    return Dialog(
      // shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.all(Radius.circular(10.0))),
      //insetPadding: EdgeInsets.zero,
      insetPadding: EdgeInsets.all(10),
      child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: isDesktopMode ? 600 : screenWidth - 20,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              //padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Scaffold(
                  appBar: AppBar(
                    leadingWidth: 200,
                    leading: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 15,
                          ),
                          ElevatedButton(
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7))),
                              elevation:
                                  MaterialStateProperty.resolveWith<double>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return 10.0;
                                  }
                                  return 5.0;
                                },
                              ),
                              // backgroundColor:
                              //     MaterialStateProperty.all(Colors.green),
                            ),
                            onPressed: () {
                              addEditorItem();
                            },
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.add,
                                ),
                                Text(
                                  "New project",
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context, null);
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                        tooltip: "Close",
                      ),
                      SizedBox(
                        width: 15,
                      ),
                    ],
                  ),
                  body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
              ),
            ),
          ]),
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
            return ConfirmDeleteDlg.show(context);
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
