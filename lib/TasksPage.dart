import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'HttpClient.dart';
import 'MsgList.dart';
import 'customWidgets.dart';
import 'inifiniteTaskList.dart';
import 'utils.dart';
import 'package:provider/provider.dart';
import 'MainMenu.dart';
import 'TaskMessagesPage.dart';
import 'LoginPage.dart';
import 'ProjectsList.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

//import 'customWidgets.dart';
import 'main.dart';
import 'dart:convert';
import 'highlight_text.dart';

class TasksPage extends StatefulWidget {
  final MsgListProvider msgListProvider;
  const TasksPage({Key? key, required this.msgListProvider}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late TasksListProvider tasksListProvider;
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  bool showSearch = isDesktopMode;

  late FloatingActionButton floatingActionButton;

  @override
  void initState() {
    super.initState();

    tasksListProvider = Provider.of<TasksListProvider>(context, listen: false);
    //msgListProvider = Provider.of<MsgListProvider>(context, listen: false);

    floatingActionButton = FloatingActionButton(
      onPressed: () {
        if (!tasksListProvider.taskEditMode) {
          tasksListProvider.addEditorItem();
          tasksListProvider.taskEditMode = true;
        }
      },
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );

    tasksListProvider.projectID = settings.getInt("projectID");

    /*itemPositionsListener.itemPositions.addListener(() {
      if (!tasksListProvider.loading &&
          !tasksListProvider.searchMode &&
          (itemPositionsListener.itemPositions.value.isEmpty ||
              (itemPositionsListener.itemPositions.value.last.index >=
                  tasksListProvider.items.length - 10))) {
        requestTasks(tasksListProvider, context);
      }
    });*/

    requestTasks(tasksListProvider, context);
  }

  Future<bool> initBeforeBuild(BuildContext context) async {
    if (tasksListProvider.projectID == null ||
        tasksListProvider.projectID == 0) {
      tasksListProvider.project = await requestFirstItem();
      if (tasksListProvider.project != null) {
        tasksListProvider.projectID = tasksListProvider.project!.ID;
        await requestTasks(tasksListProvider, context);
      }
    }

    if (tasksListProvider.projectID != null &&
        tasksListProvider.project == null) {
      tasksListProvider.project = await getProject(tasksListProvider.projectID);
      if (tasksListProvider.project == null) {
        tasksListProvider.project = await requestFirstItem();
        if (tasksListProvider.project != null) {
          tasksListProvider.projectID = tasksListProvider.project!.ID;
          await requestTasks(tasksListProvider, context);
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: initBeforeBuild(context),
        builder: (context, snapshot) {
          return /*GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: */
              Scaffold(
                  appBar: TasksPageAppBar(tasksPageState: this),
                  body: renderBody(),
                  floatingActionButton:
                      !isDesktopMode ? floatingActionButton : null);
        });
  }

  Widget renderTasks() {
    return Consumer<TasksListProvider>(builder: (context, provider, child) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
              child: NotificationListener<ScrollUpdateNotification>(
            child: InifiniteTaskList(
              scrollController: _scrollController,
              itemPositionsListener: itemPositionsListener,
              onDeleteFn: deleteTask,
              onAddFn: onAddTask,
              msgListProvider: widget.msgListProvider,
            ),
            onNotification: (notification) {
              if (!tasksListProvider.loading &&
                  !tasksListProvider.searchMode &&
                  (itemPositionsListener.itemPositions.value.isEmpty ||
                      (itemPositionsListener.itemPositions.value.last.index >=
                          tasksListProvider.items.length - 10))) {
                requestTasks(tasksListProvider, context);
              }
              return true;
            },
          ))
        ],
      );
    });
  }

  Widget renderMessages() {
    if (tasksListProvider.currentTask != null) {
      widget.msgListProvider.taskID = tasksListProvider.currentTask!.ID;
      widget.msgListProvider.task = tasksListProvider.currentTask;
      if (tasksListProvider.searchMode) {
        widget.msgListProvider.foundMessageID =
            tasksListProvider.currentTask!.lastMessageID;
      } else {
        widget.msgListProvider.foundMessageID = 0;
      }
    }

    var currentTask = tasksListProvider.currentTask;
    currentTask ??= Task(ID: 0);
    return Expanded(
        flex: 6,
        child: TaskMessagesPage(
          task: currentTask,
          msgListProvider: widget.msgListProvider,
        ));
    /*return Expanded(
        flex: 6,
        child: tasksListProvider.currentTask != null
            ? TaskMessagesPage(task: tasksListProvider.currentTask!)
            : const Center(child: Text("No any task was selected")));*/
  }

  Widget renderBody() {
    if (isDesktopMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //mainAxisAlignment: MainAxisAlignment.,
        children: [
          Expanded(flex: 4, child: renderTasks()),
          const VerticalDivider(
            indent: 0.1,
            endIndent: 0.1,
            color: Colors.grey,
          ),
          renderMessages(),
          //Expanded(flex: 6, child: const Text("data")),

          //renderTasks(),
          /*Expanded(
              child: currentTask != null
                  ? const Text("data") //TaskMessagesPage(task: currentTask!)
                  : const Text("data"))*/
        ],
      );
    } else {
      return Center(
        child: renderTasks(),
      );
    }
  }

  Future<Task?> createTask(String description) async {
    if (sessionID == "") {
      return null;
    }

    Task task = Task(Description: description);
    Response response;
    try {
      response = await httpClient.post(setUriProperty(serverURI, path: 'todo'),
          body: jsonEncode(task),
          headers: {"ProjectID": tasksListProvider.projectID.toString()});
    } catch (e) {
      return null;
    }
    //request.headers.contentLength = utf8.encode(body).length;

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      task.projectID = data["ProjectID"];
      task.ID = data["ID"];
      task.Creation_date =
          DateTime.tryParse(data["Creation_date"]) ?? DateTime.utc(0);
      task.authorID = data["AuthorID"];
      task.authorName = data["AuthorName"];
      task.read = true;
      widget.msgListProvider.task = task;
      widget.msgListProvider.taskID = task.ID;
      createMessage(
          text: "",
          msgListProvider: widget.msgListProvider,
          isTaskDescriptionItem: true);
      return task;
    }

    return null;
  }

  Future<bool> onAddTask(String description) async {
    if (sessionID == "") {
      return false;
    }

    Task? task = await createTask(description);

    if (task == null) return false;

    tasksListProvider.currentTask = task;
    tasksListProvider.addItem(task);
    widget.msgListProvider.taskID = task.ID;
    widget.msgListProvider.task = task;

    if (isDesktopMode) {
      widget.msgListProvider.clear(true);
    } else {
      widget.msgListProvider.clear(false);
      openTask(context, task, widget.msgListProvider);
    }

    return true;
  }

  Future<bool> deleteTask(int taskID) async {
    if (sessionID == "") {
      return false;
    }

    Response response;

    try {
      response = await httpClient
          .delete(setUriProperty(serverURI, path: 'todo/$taskID'));
    } catch (e) {
      return false;
    }

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }

  Future<void> searchTasks(String search, BuildContext context) async {
    if (search.isEmpty) {
      await requestTasks(tasksListProvider, context);
      return;
    }
    tasksListProvider.clear();
    List<Task> res = [];

    if (sessionID == "") {
      return;
    }

    tasksListProvider.loading = true;

    var url = setUriProperty(serverURI, path: 'searchTasks', queryParameters: {
      "ProjectID": tasksListProvider.projectID.toString(),
      "search": search,
    });

    Response response;
    try {
      response = await httpClient.get(url);
    } catch (e) {
      tasksListProvider.refresh();
      return;
    }

    if (response.statusCode == 200 && response.body != "") {
      var data = jsonDecode(response.body);

      var tasks = data["tasks"];

      if (tasks == null) {
        tasksListProvider.refresh();
        return;
      }

      /*     if (tasks.length > 0) {
        var lastItem = tasks[tasks.length - 1];
        tasksListProvider.lastID = lastItem["ID"];
        tasksListProvider.lastCreation_date =
            DateTime.tryParse(lastItem["Creation_date"]);
      }*/
      for (var item in tasks) {
        res.add(Task.fromJson(item));
      }
      if (tasks.length > 0) {
        res[0].read = true;
        res[0].unreadMessages = 0;
        tasksListProvider.currentTask = Task.fromJson(tasks[0]);
      } else {
        tasksListProvider.currentTask = null;
      }
    } else if (response.statusCode == 401) {
      bool result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    tasksListProvider.loading = false;

    if (res.isNotEmpty) {
      tasksListProvider.items = [...tasksListProvider.items, ...res];
    }
    tasksListProvider.refresh();
  }

  Future<void> requestTasks(
      TasksListProvider tasksListProvider, BuildContext context,
      [bool forceRefresh = false]) async {
    List<Task> res = [];

    if (sessionID == "") {
      return;
    }

    tasksListProvider.loading = true;

    /*var url = Uri.parse("http://" +
        serverURI +
        '/tasks' +
        toUrlParams({
          "ProjectID": tasksListProvider.projectID.toString(),
          "lastID": tasksListProvider.lastID.toString(),
          "lastCreation_date": tasksListProvider.lastCreation_date.toString(),
          "limit": "25",
        }));*/

    var url = setUriProperty(serverURI, path: 'tasks', queryParameters: {
      "ProjectID": tasksListProvider.projectID.toString(),
      "lastID": tasksListProvider.lastID.toString(),
      "lastCreation_date": tasksListProvider.lastCreation_date.toString(),
      "limit": "25",
    });

    Response response;
    try {
      //response = await httpClient.get(url, headers: {"sessionID": sessionID});
      response = await httpClient.get(url);
    } catch (e) {
      return;
    }

    if (response.statusCode == 200 && response.body != "") {
      var data = jsonDecode(response.body);

      var tasks = data["tasks"];

      if (tasks == null) return;

      if (tasks.length > 0) {
        var lastItem = tasks[tasks.length - 1];
        tasksListProvider.lastID = lastItem["ID"];
        tasksListProvider.lastCreation_date =
            DateTime.tryParse(lastItem["Creation_date"]);

        for (var item in tasks) {
          res.add(Task.fromJson(item));
        }

        if (tasksListProvider.currentTask == null ||
            tasksListProvider.currentTask!.projectID !=
                tasksListProvider.projectID) {
          tasksListProvider.currentTask = Task.fromJson(tasks[0]);
          res[0].read = true;
          res[0].unreadMessages = 0;
          widget.msgListProvider.task = tasksListProvider.currentTask;
          widget.msgListProvider.taskID = widget.msgListProvider.task?.ID ?? 0;
          widget.msgListProvider.clear();
          if (isDesktopMode) {
            widget.msgListProvider.requestMessages();
          }
        }
      } else if (tasksListProvider.items.isEmpty) {
        tasksListProvider.currentTask == null;
        widget.msgListProvider.clear(true);
      }
    } else if (response.statusCode == 401) {
      bool result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    tasksListProvider.loading = false;

    if (res.isNotEmpty || forceRefresh) {
      tasksListProvider.items = [...tasksListProvider.items, ...res];
      tasksListProvider.refresh();
    }
  }

  void _scrollDown() {
    _scrollController.jumpTo(index: tasksListProvider.items.length - 1);
  }

  void _scrollUp() {
    _scrollController.jumpTo(index: 0);
  }
}

class TasksPageAppBar extends StatefulWidget with PreferredSizeWidget {
  final _TasksPageState tasksPageState;

  TasksPageAppBar({Key? key, required this.tasksPageState}) : super(key: key);

  @override
  State<TasksPageAppBar> createState() => _TasksPageAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TasksPageAppBarState extends State<TasksPageAppBar> {
  TextEditingController searchController = TextEditingController();
  /*late TasksListProvider _taskListProvider;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _taskListProvider =
        Provider.of<TasksListProvider>(this.context, listen: false);
  }*/

  Widget getProjectField() {
    return Align(
        alignment: Alignment.topLeft,
        child: TextButton.icon(
          onPressed: () async {
            var res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProjectsPage()),
            );
            if (res != null &&
                widget.tasksPageState.tasksListProvider.project != res) {
              widget.tasksPageState.tasksListProvider.project = res;
              widget.tasksPageState.tasksListProvider.projectID = res.ID;
              widget.tasksPageState.tasksListProvider.clear();
              await widget.tasksPageState.requestTasks(
                  widget.tasksPageState.tasksListProvider, context, true);
              //widget.tasksPageState.tasksListProvider.setProjectID(res.ID);
              await settings.setInt("projectID", res.ID);
            }
            setState(() {});
          },

          label: widget.tasksPageState.tasksListProvider.project == null
              ? const Text("")
              : Text(
                  widget.tasksPageState.tasksListProvider.project
                          ?.Description ??
                      "",
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.black,
          ),
          //style: TextStyle(color: Colors.white),
        ));
  }

  Widget getSearchField() {
    return getTextField(
        controller: searchController,
        hintText: "Search",
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search),
        onCleared: () {
          widget.tasksPageState.tasksListProvider.currentTask = null;
          widget.tasksPageState.widget.msgListProvider.clear();
          widget.tasksPageState.tasksListProvider.clear();
          setState(() {
            widget.tasksPageState.tasksListProvider.searchMode = false;
            widget.tasksPageState.showSearch = isDesktopMode;
          });
          widget.tasksPageState.tasksListProvider.refresh();
          widget.tasksPageState
              .requestTasks(widget.tasksPageState.tasksListProvider, context);
        },
        onFieldSubmitted: (value) async {
          if (value.isNotEmpty) {
            widget.tasksPageState.widget.msgListProvider.clear();
            widget.tasksPageState.tasksListProvider.searchMode = true;
            widget.tasksPageState.tasksListProvider.searchHighlightedWords =
                getHighlightedWords(value);
            widget.tasksPageState.tasksListProvider.clear();
            widget.tasksPageState.tasksListProvider.refresh();

            await widget.tasksPageState.searchTasks(value, context);
            widget.tasksPageState.widget.msgListProvider.taskID =
                widget.tasksPageState.tasksListProvider.currentTask?.ID ?? 0;
            widget.tasksPageState.widget.msgListProvider.task =
                widget.tasksPageState.tasksListProvider.currentTask;
            widget.tasksPageState.widget.msgListProvider.requestMessages();
          } else {
            widget.tasksPageState.tasksListProvider.searchMode = false;
          }
        });
  }

  Widget getAppBarTitle() {
    if (isDesktopMode) {
      return Row(children: [
        Flexible(fit: FlexFit.tight, flex: 4, child: getSearchField()),
        const Text(
          "Project: ",
          style: TextStyle(fontSize: 15, color: Colors.black),
        ),
        Flexible(
            fit: FlexFit.tight,
            //flex: 6,
            child: getProjectField())
      ]);
    } else if (widget.tasksPageState.showSearch) {
      return getSearchField();
    } else {
      return getProjectField();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(240, 255, 255, 255),
      //title: Text("ToDo Chat"),
      title: getAppBarTitle(),
      /*const Expanded(
              child: TextField(
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
                  )))),*/
      leading: const MainMenu(),
      actions: [
        if (!widget.tasksPageState.showSearch)
          IconButton(
            onPressed: () {
              setState(() {
                widget.tasksPageState.showSearch = true;
              });
            },
            icon: const Icon(
              Icons.search,
              color: Colors.black,
            ),
            tooltip: "Search",
          ),
        if (isDesktopMode)
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  style: ButtonStyle(
                      elevation: MaterialStateProperty.resolveWith<double>(
                        (Set<MaterialState> states) {
                          // if the button is pressed the elevation is 10.0, if not
                          // it is 5.0
                          if (states.contains(MaterialState.pressed)) {
                            return 10.0;
                          }
                          return 5.0;
                        },
                      ),
                      backgroundColor: MaterialStateProperty.all(Colors.green)),
                  /*style: OutlinedButton.styleFrom(
                  fixedSize: const Size(60, 30),
                  side: const BorderSide(width: 1.0, color: Colors.white),
                  shape: const StadiumBorder(),
                ),*/
                  onPressed: () {
                    if (!widget.tasksPageState.tasksListProvider.taskEditMode) {
                      widget.tasksPageState.tasksListProvider.addEditorItem();
                      widget.tasksPageState.tasksListProvider.taskEditMode =
                          true;
                    }
                  },
                  child: Row(
                    children: const [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      Text(
                        "New task",
                        style: TextStyle(color: Colors.white),
                      )
                    ],
                    //tooltip: "New task",
                  )))
      ],
    );
  }
}
