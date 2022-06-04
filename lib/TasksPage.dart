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

//late TasksListProvider taskListProvider;

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  bool showSearch = isDesktopMode;

  late FloatingActionButton floatingActionButton;

  @override
  void initState() {
    super.initState();

    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);
    //msgListProvider = Provider.of<MsgListProvider>(context, listen: false);

    floatingActionButton = FloatingActionButton(
      onPressed: () {
        if (!taskListProvider.taskEditMode) {
          taskListProvider.addEditorItem();
          taskListProvider.taskEditMode = true;
        }
      },
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );

    taskListProvider.projectID = settings.getInt("projectID");

    /*itemPositionsListener.itemPositions.addListener(() {
      if (!taskListProvider.loading &&
          !taskListProvider.searchMode &&
          (itemPositionsListener.itemPositions.value.isEmpty ||
              (itemPositionsListener.itemPositions.value.last.index >=
                  taskListProvider.items.length - 10))) {
        requestTasks(taskListProvider. context);
      }
    });*/

    taskListProvider.requestTasks(context);
  }

  Future<bool> initBeforeBuild(
      BuildContext context, TasksListProvider taskListProvider) async {
    if (taskListProvider.projectID == null || taskListProvider.projectID == 0) {
      if (sessionID.isEmpty) {
        final res = await login(context: context);
        if (!res) {
          await openLoginPage(context);
        }
      }
      taskListProvider.project = await requestFirstItem();
      if (taskListProvider.project != null) {
        taskListProvider.projectID = taskListProvider.project!.ID;
        await taskListProvider.requestTasks(context);
      }
    }

    if (taskListProvider.projectID != null &&
        taskListProvider.project == null) {
      taskListProvider.project = await getProject(taskListProvider.projectID);
      if (taskListProvider.project == null) {
        taskListProvider.project = await requestFirstItem();
        if (taskListProvider.project != null) {
          taskListProvider.projectID = taskListProvider.project!.ID;
          await taskListProvider.requestTasks(context);
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);
    return FutureBuilder<bool>(
        future: initBeforeBuild(context, taskListProvider),
        builder: (context, snapshot) {
          return /*GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: */
              Scaffold(
                  appBar: TasksPageAppBar(tasksPageState: this),
                  body: renderBody(taskListProvider),
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
            ),
            onNotification: (notification) {
              if (!provider.loading &&
                  !provider.searchMode &&
                  (itemPositionsListener.itemPositions.value.isEmpty ||
                      (itemPositionsListener.itemPositions.value.last.index >=
                          provider.items.length - 10))) {
                provider.requestTasks(context);
              }
              return true;
            },
          ))
        ],
      );
    });
  }

  Widget renderMessages(TasksListProvider taskListProvider) {
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);

    if (taskListProvider.currentTask != null) {
      msgListProvider.taskID = taskListProvider.currentTask!.ID;
      msgListProvider.task = taskListProvider.currentTask;
      if (taskListProvider.searchMode) {
        msgListProvider.foundMessageID =
            taskListProvider.currentTask!.lastMessageID;
      } else {
        msgListProvider.foundMessageID = 0;
      }
    }

    var currentTask = taskListProvider.currentTask;
    currentTask ??= Task(ID: 0);
    return Expanded(
        flex: 6,
        child: TaskMessagesPage(
          task: currentTask,
        ));
    /*return Expanded(
        flex: 6,
        child: taskListProvider.currentTask != null
            ? TaskMessagesPage(task: taskListProvider.currentTask!)
            : const Center(child: Text("No any task was selected")));*/
  }

  Widget renderBody(TasksListProvider taskListProvider) {
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
          renderMessages(taskListProvider),
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

    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);

    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);

    Task task = Task(description: description);
    Response response;
    try {
      response = await httpClient.post(setUriProperty(serverURI, path: 'todo'),
          body: jsonEncode(task),
          headers: {"ProjectID": taskListProvider.projectID.toString()});
    } catch (e) {
      return null;
    }
    //request.headers.contentLength = utf8.encode(body).length;

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      task.projectID = data["ProjectID"];
      task.ID = data["ID"];
      task.creation_date =
          DateTime.tryParse(data["Creation_date"]) ?? DateTime.utc(0);
      task.authorID = data["AuthorID"];
      task.authorName = data["AuthorName"];
      task.read = true;
      msgListProvider.task = task;
      msgListProvider.taskID = task.ID;
      createMessage(
          text: "",
          msgListProvider: msgListProvider,
          isTaskDescriptionItem: true);
      return task;
    }

    return null;
  }

  Future<bool> onAddTask(String description) async {
    if (sessionID == "") {
      return false;
    }

    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);

    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);

    Task? task = await createTask(description);

    if (task == null) return false;

    taskListProvider.currentTask = task;
    taskListProvider.addItem(task);
    msgListProvider.taskID = task.ID;
    msgListProvider.task = task;

    if (isDesktopMode) {
      msgListProvider.clear(true);
    } else {
      msgListProvider.clear(false);
      openTask(context, task, msgListProvider);
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
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);

    if (search.isEmpty) {
      await taskListProvider.requestTasks(context);
      return;
    }
    taskListProvider.clear();
    List<Task> res = [];

    if (sessionID == "") {
      return;
    }

    taskListProvider.loading = true;

    var url = setUriProperty(serverURI, path: 'searchTasks', queryParameters: {
      "ProjectID": taskListProvider.projectID.toString(),
      "search": search,
    });

    Response response;
    try {
      response = await httpClient.get(url);
    } catch (e) {
      taskListProvider.refresh();
      return;
    }

    if (response.statusCode == 200 && response.body != "") {
      var data = jsonDecode(response.body);

      var tasks = data["tasks"];

      if (tasks == null) {
        taskListProvider.currentTask = null;
        taskListProvider.refresh();
        msgListProvider.clear(true);
        return;
      }

      /*     if (tasks.length > 0) {
        var lastItem = tasks[tasks.length - 1];
        taskListProvider.lastID = lastItem["ID"];
        taskListProvider.lastCreation_date =
            DateTime.tryParse(lastItem["Creation_date"]);
      }*/
      for (var item in tasks) {
        res.add(Task.fromJson(item));
      }
      if (tasks.length > 0) {
        res[0].read = true;
        res[0].unreadMessages = 0;
        taskListProvider.currentTask = Task.fromJson(tasks[0]);
      } else {
        taskListProvider.currentTask = null;
      }
    } else if (response.statusCode == 401) {
      bool result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    taskListProvider.loading = false;

    if (res.isNotEmpty) {
      taskListProvider.items = [...taskListProvider.items, ...res];
    }
    taskListProvider.refresh();
  }

  /*Future<void> requestTasks(
      TasksListProvider taskListProvider, BuildContext context,
      [bool forceRefresh = false]) async {
    List<Task> res = [];

    if (sessionID == "") {
      return;
    }

    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    taskListProvider.loading = true;

    /*var url = Uri.parse("http://" +
        serverURI +
        '/tasks' +
        toUrlParams({
          "ProjectID": taskListProvider.projectID.toString(),
          "lastID": taskListProvider.lastID.toString(),
          "lastCreation_date": taskListProvider.lastCreation_date.toString(),
          "limit": "25",
        }));*/

    var url = setUriProperty(serverURI, path: 'tasks', queryParameters: {
      "ProjectID": taskListProvider.projectID.toString(),
      "lastID": taskListProvider.lastID.toString(),
      "lastCreation_date": taskListProvider.lastCreation_date.toString(),
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
        taskListProvider.lastID = lastItem["ID"];
        taskListProvider.lastCreation_date =
            DateTime.tryParse(lastItem["Creation_date"]);

        for (var item in tasks) {
          res.add(Task.fromJson(item));
        }

        if (taskListProvider.currentTask == null ||
            taskListProvider.currentTask!.projectID !=
                taskListProvider.projectID) {
          taskListProvider.currentTask = Task.fromJson(tasks[0]);
          res[0].read = true;
          res[0].unreadMessages = 0;
          msgListProvider.task = taskListProvider.currentTask;
          msgListProvider.taskID = msgListProvider.task?.ID ?? 0;
          msgListProvider.clear();
          if (isDesktopMode) {
            msgListProvider.requestMessages();
          }
        }
      } else if (taskListProvider.items.isEmpty) {
        taskListProvider.currentTask == null;
        msgListProvider.clear(true);
      }
    } else if (response.statusCode == 401) {
      bool result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    taskListProvider.loading = false;

    if (res.isNotEmpty || forceRefresh) {
      taskListProvider.items = [...taskListProvider.items, ...res];
      taskListProvider.refresh();
    }
  }*/
/*
  void _scrollDown() {
    _scrollController.jumpTo(index: taskListProvider.items.length - 1);
  }

  void _scrollUp() {
    _scrollController.jumpTo(index: 0);
  }*/
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
  /*late taskListProvider._taskListProvider;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _taskListProvider =
        Provider.of<taskListProvider.(this.context, listen: false);
  }*/

  Widget getProjectField() {
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);
    return Align(
        alignment: Alignment.topLeft,
        child: TextButton.icon(
          onPressed: () async {
            var res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProjectsPage()),
            );
            if (res != null && taskListProvider.project != res) {
              taskListProvider.project = res;
              taskListProvider.projectID = res.ID;
              taskListProvider.clear();
              await taskListProvider.requestTasks(context, true);
              //taskListProvider.setProjectID(res.ID);
              await settings.setInt("projectID", res.ID);
            }
            setState(() {});
          },

          label: taskListProvider.project == null
              ? const Text("")
              : Text(
                  taskListProvider.project?.Description ?? "",
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
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    return getTextField(
        controller: searchController,
        hintText: "Search",
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search),
        onCleared: () {
          taskListProvider.currentTask = null;
          msgListProvider.clear();
          taskListProvider.clear();
          setState(() {
            taskListProvider.searchMode = false;
            widget.tasksPageState.showSearch = isDesktopMode;
          });
          taskListProvider.refresh();
          taskListProvider.requestTasks(context);
        },
        onFieldSubmitted: (value) async {
          if (value.isNotEmpty) {
            msgListProvider.clear();
            taskListProvider.searchMode = true;
            taskListProvider.searchHighlightedWords =
                getHighlightedWords(value);
            taskListProvider.clear();
            taskListProvider.refresh();

            await widget.tasksPageState.searchTasks(value, context);
            msgListProvider.taskID = taskListProvider.currentTask?.ID ?? 0;
            msgListProvider.task = taskListProvider.currentTask;
            msgListProvider.requestMessages();
          } else {
            taskListProvider.searchMode = false;
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
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);
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
                    if (!taskListProvider.taskEditMode) {
                      taskListProvider.addEditorItem();
                      taskListProvider.taskEditMode = true;
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
