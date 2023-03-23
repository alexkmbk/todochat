import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:todochat/tasklist_provider.dart';
import 'HttpClient.dart';
import 'msglist.dart';
import 'customWidgets.dart';
import 'msglist_provider.dart';
import 'tasklist.dart';
import 'package:provider/provider.dart';
import 'main_menu.dart';
import 'TaskMessagesPage.dart';
import 'LoginPage.dart';
import 'ProjectsList.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

//import 'customWidgets.dart';
import 'todochat.dart';
import 'dart:convert';
import 'highlight_text.dart';
//import 'package:resizable_widget/resizable_widget.dart';
import 'package:multi_split_view/multi_split_view.dart';

//late TaskListProvider taskListProvider;

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

    /*final taskListProvider =
        Provider.of<TaskListProvider>(context, listen: false);*/
    //msgListProvider = Provider.of<MsgListProvider>(context, listen: false);

    //  taskListProvider.projectID = settings.getInt("projectID");

    /*itemPositionsListener.itemPositions.addListener(() {
      if (!taskListProvider.loading &&
          !taskListProvider.searchMode &&
          (itemPositionsListener.itemPositions.value.isEmpty ||
              (itemPositionsListener.itemPositions.value.last.index >=
                  taskListProvider.items.length - 10))) {
        requestTasks(taskListProvider. context);
      }
    });*/

    //taskListProvider.requestTasks(context);
  }

  Future<bool> initBeforeBuild(
      BuildContext context, TaskListProvider taskListProvider) async {
/*    if (taskListProvider.projectID == null || taskListProvider.projectID == 0) {
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
    }*/
    return true;
  }

  Widget floatingActionButtonToSave(
      TaskListProvider provider, BuildContext context) {
    return SizedBox(
        width: 100,
        child: FloatingActionButton(
          shape: const StadiumBorder(),
          onPressed: () {
            provider.saveEditingItem(context);
          },
          child: const Text("Save"),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskListProvider>(builder: (context, provider, child) {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
            child: Scaffold(
                appBar: TasksPageAppBar(tasksPageState: this),
                body: renderBody(provider),
                floatingActionButton: !isDesktopMode
                    ? provider.taskEditMode
                        ? floatingActionButtonToSave(provider, context)
                        : FloatingActionButton(
                            onPressed: () {
                              if (!provider.taskEditMode) {
                                provider.addEditorItem();
                              }
                            },
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                          )
                    : null))
      ]);
    });
  }

  Widget renderTasks(TaskListProvider taskListProvider) {
    return NotificationListener<ScrollUpdateNotification>(
      child: TaskList(
        scrollController: _scrollController,
        itemPositionsListener: itemPositionsListener,
      ),
      onNotification: (notification) {
        /*var scrollDelta = notification.scrollDelta ?? 0;
        if (taskListProvider.items.length >
            itemPositionsListener.itemPositions.value.last.index + 5) {
          final double? sign = scrollDelta.sign;
          final index = itemPositionsListener.itemPositions.value.last.index +
              (5 * (sign ?? 1)).toInt();
          _scrollController.jumpTo(index: index);
        }*/

        if (!taskListProvider.loading &&
            !taskListProvider.searchMode &&
            (itemPositionsListener.itemPositions.value.isEmpty ||
                (itemPositionsListener.itemPositions.value.last.index >=
                    taskListProvider.items.length - 10))) {
          //taskListProvider.requestTasks(context);
        }
        return true;
      },
    );
  }

  Widget renderMessages(TaskListProvider taskListProvider) {
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
    return TaskMessagesPage(
      task: currentTask,
    );
    /*return Expanded(
        flex: 6,
        child: taskListProvider.currentTask != null
            ? TaskMessagesPage(task: taskListProvider.currentTask!)
            : const Center(child: Text("No any task was selected")));*/
  }

  Widget renderBody(TaskListProvider taskListProvider) {
    if (isDesktopMode) {
      return MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
              dividerThickness: 2,
              dividerPainter: DividerPainters.background(
                animationEnabled: false,
                highlightedColor: Colors.blue,
                color: Colors.blueGrey.shade100,
              )),
          child: MultiSplitView(
            initialAreas: [Area(weight: 0.3)],
            /*key: UniqueKey(),
        separatorColor: Colors.blueGrey.shade100,
        separatorSize: 2,
        isHorizontalSeparator: false,
        isDisabledSmartHide: false,
        percentages: const [0.3, 0.7],*/
            //crossAxisAlignment: CrossAxisAlignment.start,
            //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //mainAxisAlignment: MainAxisAlignment.,
            children: [
              renderTasks(taskListProvider),
              //Expanded(flex: 4, child: renderTasks(taskListProvider)),
              /*const VerticalDivider(
            indent: 0.1,
            endIndent: 0.1,
            color: Colors.grey,
          ),*/
              renderMessages(taskListProvider),
              //Expanded(flex: 6, child: const Text("data")),

              //renderTasks(),
              /*Expanded(
              child: currentTask != null
                  ? const Text("data") //TaskMessagesPage(task: currentTask!)
                  : const Text("data"))*/
            ],
          ));
    } else {
      return Center(
        child: renderTasks(taskListProvider),
      );
    }
  }

  Future<void> searchTasks(String search, BuildContext context) async {
    final taskListProvider =
        Provider.of<TaskListProvider>(context, listen: false);
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
      "showCompleted": taskListProvider.showCompleted.toString(),
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
        Provider.of<TaskListProvider>(context, listen: false);
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
        Provider.of<TaskListProvider>(context, listen: false);
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    return getTextField(
        focusNode: searchFocusNode,
        textInputAction: TextInputAction.done,
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
          taskListProvider.search = value;
          if (value.isNotEmpty) {
            msgListProvider.clear();
            taskListProvider.searchMode = true;
            taskListProvider.searchHighlightedWords =
                getHighlightedWords(value);
            taskListProvider.clear();
            taskListProvider.refresh();

            await widget.tasksPageState.searchTasks(value, context);
            if (isDesktopMode) {
              msgListProvider.taskID = taskListProvider.currentTask?.ID ?? 0;
              msgListProvider.task = taskListProvider.currentTask;
              msgListProvider.requestMessages(taskListProvider, context);
            }
          } else {
            taskListProvider.searchMode = false;
          }
          //FocusScope.of(context).requestFocus();
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
        Provider.of<TaskListProvider>(context, listen: false);
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
      leading: MainMenu(
        key: UniqueKey(),
        items: [
          PopupMenuItem(
            child: Text(taskListProvider.showCompleted
                ? "Hide completed"
                : "Show completed"),
            onTap: () async {
              taskListProvider.showCompleted = !taskListProvider.showCompleted;
              settings.setBool("showCompleted", taskListProvider.showCompleted);
              taskListProvider.clear();
              if (taskListProvider.search.isNotEmpty) {
                widget.tasksPageState
                    .searchTasks(taskListProvider.search, context);
              } else {
                taskListProvider.requestTasks(context, true);
              }
            },
          ),
        ],
      ),
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
