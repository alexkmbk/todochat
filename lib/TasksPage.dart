import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:todochat/MsgList.dart';
import 'package:todochat/customWidgets.dart';
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
import 'package:collection/collection.dart';
import 'highlight_text.dart';

class Task {
  int ID = 0;
  int projectID = 0;
  int authorID = 0;
  bool Completed = false;
  String Description = "";
  String lastMessage = "";
  int lastMessageID = 0;
  bool editMode = false;
  DateTime Creation_date = DateTime.utc(0);
  bool isNewItem = false;

  Task(
      {this.ID = 0,
      this.Description = "",
      this.Completed = false,
      this.editMode = false,
      this.isNewItem = false});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'Completed': Completed,
      'Description': Description,
      'LastMessage': lastMessage,
      'LastMessageID': lastMessageID,
      'ProjectID': projectID,
      'AuthorID': authorID,
      'Creation_date': Creation_date.toIso8601String(),
    };
  }

  Task.fromJson(Map<String, dynamic> json)
      : ID = json['ID'],
        Creation_date =
            DateTime.tryParse(json['Creation_date']) ?? DateTime.utc(0),
        Completed = json['Completed'],
        Description = json['Description'],
        lastMessage = json['LastMessage'],
        lastMessageID = json['LastMessageID'],
        projectID = json['ProjectID'],
        authorID = json['AuthorID'];

  Task.from(Task task) {
    ID = task.ID;
    Description = task.Description;
    Creation_date = task.Creation_date;
    Completed = task.Completed;
    lastMessage = task.lastMessage;
    lastMessageID = task.lastMessageID;
    projectID = task.projectID;
    authorID = task.authorID;
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late TasksListProvider tasksListProvider;
  late MsgListProvider msgListProvider;
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  bool showSearch = isDesktopMode;

  @override
  void initState() {
    super.initState();

    tasksListProvider = Provider.of<TasksListProvider>(context, listen: false);
    msgListProvider = Provider.of<MsgListProvider>(context, listen: false);

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
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: initBeforeBuild(context),
        builder: (context, snapshot) {
          return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Scaffold(
                appBar: TasksPageAppBar(tasksPageState: this),
                body: renderBody(),
              ));
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
                onAddFn: onAddTask),
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
      msgListProvider.taskID = tasksListProvider.currentTask!.ID;
      if (tasksListProvider.searchMode) {
        msgListProvider.foundMessageID =
            tasksListProvider.currentTask!.lastMessageID;
      } else {
        msgListProvider.foundMessageID = 0;
      }
    }

    return Expanded(
        flex: 6,
        child: tasksListProvider.currentTask != null
            ? TaskMessagesPage(task: tasksListProvider.currentTask!)
            : const Center(child: Text("No any task was selected")));
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

  Future<Task?> createTask(String Description) async {
    if (sessionID == "") {
      return null;
    }

    Task task = Task(Description: Description);
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
      return task;
    }

    return null;
  }

  Future<bool> onAddTask(String Description) async {
    if (sessionID == "") {
      return false;
    }

    Task? task = await createTask(Description);

    if (task == null) return false;

    tasksListProvider.addItem(task);
    return true;
  }

  Future<bool> deleteTask(int taskID) async {
    if (sessionID == "") {
      return false;
    }

    Response response;

    try {
      response = await httpClient
          .delete(setUriProperty(serverURI, path: 'todo/' + taskID.toString()));
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
      TasksListProvider tasksListProvider, BuildContext context) async {
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
        tasksListProvider.currentTask ??= Task.fromJson(tasks[0]);
      }
      for (var item in tasks) {
        res.add(Task.fromJson(item));
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

typedef RequestFn = Future<List<Task>> Function(TasksListProvider context);
typedef OnAddFn = Future<bool> Function(String description);
typedef OnDeleteFn = Future<bool> Function(int taskID);
typedef ItemBuilder = Widget Function(
    BuildContext context, Task item, int index);

class TasksListProvider extends ChangeNotifier {
  Project? project;
  int? projectID;
  List<Task> items = [];
  int lastID = 0;
  DateTime? lastCreation_date;
  bool loading = false;
  bool searchMode = false;
  List<String> searchHighlightedWords = [];
  Task? currentTask;

  void refresh() {
    notifyListeners();
  }

  void clear() {
    items.clear();
    lastID = 0;
    lastCreation_date = null;
  }

  void setProjectID(int? value) {
    projectID = value;
    notifyListeners();
  }

  void addEditorItem() {
    items.insert(0, Task(editMode: true, isNewItem: true));
    notifyListeners();
  }

  void deleteEditorItem() {
    items.removeWhere((item) => item.editMode == true);
    notifyListeners();
  }

  void addItem(Task task) {
    items.insert(0, task);
    notifyListeners();
  }

  void updateLastMessage(int taskID, [String lastMessage = ""]) {
    var item = items.firstWhereOrNull((element) => element.ID == taskID);
    if (item != null) {
      item.lastMessage = lastMessage;
      notifyListeners();
    }
  }

  void deleteItem(int taskID) async {
    items.removeWhere((item) => item.ID == taskID);
    notifyListeners();
  }
}

class InifiniteTaskList extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final ItemScrollController scrollController;
  final OnAddFn onAddFn;
  final OnDeleteFn onDeleteFn;

  const InifiniteTaskList(
      {Key? key,
      required this.scrollController,
      required this.itemPositionsListener,
      required this.onAddFn,
      required this.onDeleteFn})
      : super(key: key);

  @override
  InifiniteTaskListState createState() {
    return InifiniteTaskListState();
  }
}

class InifiniteTaskListState extends State<InifiniteTaskList> {
  late TasksListProvider _taskListProvider;
  late MsgListProvider _msgListProvider;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _taskListProvider = Provider.of<TasksListProvider>(context, listen: false);
    _msgListProvider = Provider.of<MsgListProvider>(context, listen: false);
  }

// This is what you're looking for!

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(
          child: ScrollablePositionedList.builder(
        padding: EdgeInsets.zero,
        itemScrollController: widget.scrollController,
        itemPositionsListener: widget.itemPositionsListener,
        //controller: widget.scrollController,
        itemBuilder: (context, index) {
          return TaskListTile(
              index: index,
              task: _taskListProvider.items[index],
              tasksListProvider: _taskListProvider,
              inifiniteTaskList: widget,
              msgListProvider: _msgListProvider);
          /*if (index < _taskListProvider.items.length) {
            return buildListRow(context, index, _taskListProvider.items[index],
                _taskListProvider, widget);
          }
          return const Center(child: Text('End of list'));*/
        },
        itemCount: _taskListProvider.items.length,
      )),
    ]);
  }
}

class TaskListTile extends StatefulWidget {
  final int index;
  final Task task;
  final TasksListProvider tasksListProvider;
  final InifiniteTaskList inifiniteTaskList;
  final MsgListProvider msgListProvider;

  const TaskListTile(
      {Key? key,
      required this.index,
      required this.task,
      required this.tasksListProvider,
      required this.inifiniteTaskList,
      required this.msgListProvider})
      : super(key: key);

  @override
  State<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<TaskListTile> {
  @override
  Widget build(BuildContext context) {
    return buildListRow(context);
  }

  Color? getTileColor(bool selected) {
    if (isDesktopMode && selected) {
      return Colors.blue[50];
    }
    return null;
  }

  Widget buildListRow(BuildContext context) {
    if (widget.task.editMode) {
      return Card(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
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
                        if (widget.task.isNewItem) {
                          widget.tasksListProvider.deleteEditorItem();
                        } else {
                          setState(() {
                            widget.task.editMode = false;
                          });
                        }
                      }
                    },
                    child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter,
                          control: false): () {
                             TextEditingControllerHelper.insertText(controller, '\n');
                        if (_messageInputController.text.isNotEmpty) {
                          createMessage(text: _messageInputController.text);
                          _messageInputController.text = "";
                        }
                      }},
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        maxLines: 10,
                        controller: TextEditingController()
                          ..text = widget.task.Description,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText:
                                widget.task.isNewItem ? "New task name" : null),
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) async {
                          if (value.isNotEmpty) {
                            if (widget.task.isNewItem) {
                              await widget.inifiniteTaskList.onAddFn(value);
                              widget.tasksListProvider.deleteEditorItem();
                            } else {
                              var tempTask = Task.from(widget.task);
                              tempTask.Description = value;
                              var res = await updateTask(tempTask);
                              if (res) {
                                setState(() {
                                  widget.task.Description =
                                      tempTask.Description;
                                  widget.task.editMode = false;
                                });
                              }
                            }
                          }
                        }),
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
          if (await widget.inifiniteTaskList.onDeleteFn(widget.task.ID)) {
            widget.tasksListProvider.deleteItem(widget.task.ID);
          }
        },
        child: Card(
            color: Color.fromARGB(255, 253, 253, 242),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0))),
            child: ListTile(
              //shape: const Border(bottom: BorderSide(color: Colors.grey)),

              tileColor: widget.tasksListProvider.currentTask == null
                  ? null
                  : getTileColor(widget.tasksListProvider.currentTask!.ID ==
                      widget.task.ID),
              onTap: () => onTap(widget.task),
              onLongPress: () => onLongPress(widget.task),
              leading: Checkbox(
                  fillColor: MaterialStateProperty.all(Colors.green),
                  value: widget.task.Completed,
                  onChanged: (value) =>
                      taskCompletedOnChanged(value, widget.task)),
              title: widget.tasksListProvider.searchMode
                  ? HighlightText(
                      highlightColor: Colors.red,
                      text: widget.task.Description,
                      words: widget.tasksListProvider.searchHighlightedWords,
                      maxLines: 5,
                    )
                  : Text(
                      widget.task.Description,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 5,
                    ),
              subtitle: widget.task.lastMessage.isEmpty
                  ? null
                  : widget.tasksListProvider.searchMode
                      ? HighlightText(
                          highlightColor: Colors.red,
                          text: widget.task.lastMessage,
                          words:
                              widget.tasksListProvider.searchHighlightedWords,
                        )
                      : Text(widget.task.lastMessage,
                          overflow: TextOverflow.ellipsis),
            )),
      );
    }
  }

  void openTask(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskMessagesPage(task: task)),
    );
  }

  Future<void> onTap(Task task) async {
    if (isDesktopMode) {
      if (sessionID == "" || !mounted) {
        return;
      }
      widget.msgListProvider.clear(true);
      widget.tasksListProvider.currentTask = task;
      widget.tasksListProvider.refresh();
      widget.msgListProvider.taskID = task.ID;
      widget.msgListProvider.loading = true;
      ws!.sink.add(jsonEncode({
        "sessionID": sessionID,
        "command": "getMessages",
        "lastID": widget.msgListProvider.lastID.toString(),
        "messageIDPosition": task.lastMessageID.toString(),
        "limit": "30",
        "taskID": widget.msgListProvider.taskID.toString(),
      }));
      /*setState(() {
        msgListProvider.clear();
        tasksListProvider.currentTask = task;
      });*/
    } else {
      openTask(context, task);
    }
  }

  void onLongPress(Task task) {
    setState(() {
      var foundTask = widget.tasksListProvider.items
          .firstWhereOrNull((element) => element.ID == task.ID);
      if (foundTask != null) {
        foundTask.editMode = true;
        foundTask.isNewItem = false;
      }
    });
  }

  void taskCompletedOnChanged(bool? value, Task task) async {
    if (value == null) return;

    setState(() {
      task.Completed = value;
    });

    var res = await updateTask(Task.from(task)..Completed = value);

    if (!res) {
      setState(() {
        task.Completed = !value;
      });
    }
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
    return Flexible(
        fit: FlexFit.tight,
        //flex: 6,
        child: Align(
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
                  widget.tasksPageState.requestTasks(
                      widget.tasksPageState.tasksListProvider, context);
                  //widget.tasksPageState.tasksListProvider.setProjectID(res.ID);
                  await settings.setInt("projectID", res.ID);
                }
                setState(() {});
              },
              label: widget.tasksPageState.tasksListProvider.project == null
                  ? const Text("")
                  : Text(
                      widget.tasksPageState.tasksListProvider.project!
                          .Description,
                      style: const TextStyle(color: Colors.white),
                    ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
              ),
              //style: TextStyle(color: Colors.white),
            )));
  }

  Widget getSearchField() {
    return Flexible(
        fit: FlexFit.tight,
        flex: 4,
        child: GetTextField(
            controller: searchController,
            hintText: "Search",
            fillColor: Colors.white,
            prefixIcon: Icon(Icons.search),
            onCleared: () {
              widget.tasksPageState.tasksListProvider.currentTask = null;
              widget.tasksPageState.msgListProvider.clear();
              widget.tasksPageState.tasksListProvider.clear();
              widget.tasksPageState.tasksListProvider.searchMode = false;
              widget.tasksPageState.showSearch = isDesktopMode;
              widget.tasksPageState.tasksListProvider.refresh();
              widget.tasksPageState.requestTasks(
                  widget.tasksPageState.tasksListProvider, context);
            },
            onFieldSubmitted: (value) async {
              if (value.isNotEmpty) {
                widget.tasksPageState.msgListProvider.clear();
                widget.tasksPageState.tasksListProvider.searchMode = true;
                widget.tasksPageState.tasksListProvider.searchHighlightedWords =
                    getHighlightedWords(value);
                widget.tasksPageState.tasksListProvider.clear();
                widget.tasksPageState.tasksListProvider.refresh();

                widget.tasksPageState.searchTasks(value, context);
              } else {
                widget.tasksPageState.tasksListProvider.searchMode = false;
              }
            }));
  }

  Widget getAppBarTitle() {
    if (isDesktopMode) {
      return Row(children: [
        getSearchField(),
        const Text(
          "Project: ",
          style: TextStyle(fontSize: 15),
        ),
        getProjectField()
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
      leading: MainMenu(),
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
              color: Colors.white,
            ),
            tooltip: "Search",
          ),
        IconButton(
          onPressed: () {
            widget.tasksPageState.tasksListProvider.addEditorItem();
          },
          icon: const Icon(
            Icons.add,
            color: Colors.white,
          ),
          tooltip: "New task",
        )
      ],
    );
  }
}

Future<bool> updateTask(Task task) async {
  if (sessionID == "") {
    return false;
  }

  Response response;

  try {
    response = await httpClient.post(
        setUriProperty(serverURI, path: 'updateTask'),
        body: jsonEncode(task));
  } catch (e) {
    return false;
  }

  if (response.statusCode == 200) {
    return true;
  }

  return false;
}
