import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class Task {
  int ID = 0;
  bool Completed = false;
  String Description = "";
  bool editMode = false;
  DateTime? Creation_date;

  Task(
      {this.ID = 0,
      this.Description = "",
      this.Completed = false,
      this.editMode = false});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'Completed': Completed,
      'Description': Description,
    };
  }

  Task.fromJson(Map<String, dynamic> json)
      : ID = json['ID'],
        Creation_date = DateTime.tryParse(json['Creation_date']),
        Completed = json['Completed'],
        Description = json['Description'];
}

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late TasksListProvider tasksListProvider;
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();

    tasksListProvider = Provider.of<TasksListProvider>(context, listen: false);

    tasksListProvider.projectID = settings.getInt("projectID");

    itemPositionsListener.itemPositions.addListener(() {
      if (!tasksListProvider.loading &&
              itemPositionsListener.itemPositions.value.length == 0 ||
          (itemPositionsListener.itemPositions.value.last.index >=
              tasksListProvider.items.length - 10)) {
        requestTasks(tasksListProvider, context);
      }
    });

    requestTasks(tasksListProvider, context);
  }

  Future<bool> initBeforeBuild(BuildContext context) async {
    if (tasksListProvider.projectID == null) {
      tasksListProvider.project = await requestFirstItem();
      if (tasksListProvider.project != null) {
        tasksListProvider.projectID = tasksListProvider.project!.ID;
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
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Consumer<TasksListProvider>(
                          builder: (context, provider, child) {
                        return Expanded(
                            child: InifiniteTaskList(
                          scrollController: _scrollController,
                          itemPositionsListener: itemPositionsListener,
                          onDeleteFn: deleteTask,
                          onAddFn: onAddTask,
                          onTap: onTap,
                        ));
                      }),
                    ],
                  ),
                ),
              ));
        });
  }

  void OpenTask(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskMessagesPage(task: task)),
    );
  }

  Future<Task?> createTask(String Description) async {
    if (sessionID == "") {
      return null;
    }

    Task task = Task(Description: Description);
    String body = jsonEncode(task);

    Map<String, String> headers = Map<String, String>();
    headers["sessionID"] = sessionID;
    headers["ProjectID"] = tasksListProvider.projectID.toString();
    headers["content-type"] = "application/json; charset=utf-8";

    var response;
    try {
      response = await httpClient.post(Uri.http(server, '/todo'),
          body: body, headers: headers);
    } catch (e) {
      return null;
    }
    //request.headers.contentLength = utf8.encode(body).length;

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      task.ID = data["ID"];
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

  Future<void> onTap(Task task) async {
    OpenTask(context, task);
  }

  Future<bool> deleteTask(int taskID) async {
    if (sessionID == "") {
      return false;
    }

    Map<String, String> headers = Map<String, String>();
    headers["sessionID"] = sessionID;

    var response;

    try {
      response = await httpClient.delete(
          Uri.http(server, '/todo/' + taskID.toString()),
          headers: headers);
    } catch (e) {
      return false;
    }

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }

  Future<void> requestTasks(
      TasksListProvider tasksListProvider, BuildContext context) async {
    List<Task> res = [];

    if (sessionID == "") {
      return;
    }

    Map<String, String> headers = Map<String, String>();
    headers["sessionID"] = sessionID;
    headers["ProjectID"] = tasksListProvider.projectID.toString();
    //headers["offset"] = tasksListProvider.offset.toString();
    headers["lastID"] = tasksListProvider.lastID.toString();
    headers["lastCreation_date"] =
        tasksListProvider.lastCreation_date.toString();
    headers["limit"] = "25";

    tasksListProvider.loading = true;

    var response;
    try {
      response = await httpClient.get(Uri.http(server, '/todoItems'),
          headers: headers);
    } catch (e) {
      return;
    }

    if (response.statusCode == 200 && response.body != "") {
      var data = jsonDecode(response.body);

      var tasks = data["tasks"];

      if (tasks == null) return;
      tasksListProvider.offset = tasksListProvider.offset + tasks.length;

      if (tasks.length > 0) {
        var lastItem = tasks[tasks.length - 1];
        tasksListProvider.lastID = lastItem["ID"];
        tasksListProvider.lastCreation_date =
            DateTime.tryParse(lastItem["Creation_date"]);
      }
      for (var item in tasks) {
        res.add(Task(
            Description: item["Description"],
            ID: item["ID"],
            Completed: item["Completed"]));
      }
    } else if (response.statusCode == 401) {
      bool result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    tasksListProvider.loading = false;

    if (res.isNotEmpty) {
      setState(
          () => tasksListProvider.items = [...tasksListProvider.items, ...res]);
    }
  }

  void _scrollDown() {
    _scrollController.jumpTo(index: tasksListProvider.items.length - 1);
  }

  void _scrollUp() {
    _scrollController.jumpTo(index: 0);
  }
}

typedef Future<List<Task>> RequestFn(TasksListProvider context);
typedef Future<bool> OnAddFn(String description);
typedef Future<bool> OnDeleteFn(int taskID);
typedef Widget ItemBuilder(BuildContext context, Task item, int index);

class TasksListProvider extends ChangeNotifier {
  Project? project;
  int? projectID;
  List<Task> items = [];
  num offset = 0;
  int lastID = 0;
  DateTime? lastCreation_date;
  bool loading = false;

  void setProjectID(int? value) {
    projectID = value;
    notifyListeners();
  }

  void addEditorItem() {
    items.insert(0, Task(editMode: true));
    notifyListeners();
  }

  void deleteEditorItem() {
    items.removeWhere((item) => item.editMode == true);
    notifyListeners();
  }

  void addItem(Task task) {
    offset++;
    items.insert(0, task);
    notifyListeners();
  }

  void deleteItem(int taskID) async {
    offset--;
    if (offset < 0) offset = 0;
    items.removeWhere((item) => item.ID == taskID);
    notifyListeners();
  }
}

class InifiniteTaskList extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final ItemScrollController scrollController;
  final OnAddFn onAddFn;
  final OnDeleteFn onDeleteFn;

  final Future<void> Function(Task task) onTap;

  const InifiniteTaskList(
      {Key? key,
      required this.scrollController,
      required this.itemPositionsListener,
      required this.onTap,
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
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _taskListProvider =
        Provider.of<TasksListProvider>(this.context, listen: false);
  }

// This is what you're looking for!

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(
          child: ScrollablePositionedList.builder(
        itemScrollController: widget.scrollController,
        itemPositionsListener: widget.itemPositionsListener,
        //controller: widget.scrollController,
        itemBuilder: (context, index) {
          return buildListRow(context, index, _taskListProvider.items[index],
              _taskListProvider, widget);
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

  Widget buildListRow(
      BuildContext context,
      index,
      Task task,
      TasksListProvider tasksListProvider,
      InifiniteTaskList inifiniteTaskList) {
    if (task.editMode) {
      return Container(
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10)),
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
                        tasksListProvider.deleteEditorItem();
                      }
                    },
                    child: TextField(
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: "New task name"),
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) async {
                        if (!value.isEmpty) {
                          await inifiniteTaskList.onAddFn(value);
                          tasksListProvider.deleteEditorItem();
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
            if (await inifiniteTaskList.onDeleteFn(task.ID)) {
              tasksListProvider.deleteItem(task.ID);
            }
          },
          child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              onTap: () => inifiniteTaskList.onTap(task),
              title: Text(task.Description),
              trailing: Icon(Icons.keyboard_arrow_right),
            ),
          ));
    }
  }
}

class TasksPageAppBar extends StatefulWidget with PreferredSizeWidget {
  final _TasksPageState tasksPageState;

  TasksPageAppBar({Key? key, required this.tasksPageState}) : super(key: key);

  @override
  State<TasksPageAppBar> createState() => _TasksPageAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _TasksPageAppBarState extends State<TasksPageAppBar> {
  /*late TasksListProvider _taskListProvider;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _taskListProvider =
        Provider.of<TasksListProvider>(this.context, listen: false);
  }*/

  @override
  Widget build(BuildContext context) {
    return AppBar(
      //title: Text("ToDo Chat"),
      title: TextButton.icon(
        onPressed: () async {
          var res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProjectsPage()),
          );
          if (res != null &&
              widget.tasksPageState.tasksListProvider.project != res) {
            widget.tasksPageState.tasksListProvider.project = res;
            widget.tasksPageState.tasksListProvider.projectID = res.ID;
            widget.tasksPageState.tasksListProvider.items.clear();
            widget.tasksPageState.tasksListProvider.lastID = 0;
            widget.tasksPageState.tasksListProvider.lastCreation_date = null;
            widget.tasksPageState
                .requestTasks(widget.tasksPageState.tasksListProvider, context);
            //widget.tasksPageState.tasksListProvider.setProjectID(res.ID);
            await settings.setInt("projectID", res.ID);
          }
          setState(() {});
        },
        label: widget.tasksPageState.tasksListProvider.project == null
            ? Text("")
            : Text(
                widget.tasksPageState.tasksListProvider.project!.Description,
                style: TextStyle(color: Colors.white),
              ),
        icon: Icon(Icons.keyboard_arrow_down),
        //style: TextStyle(color: Colors.white),
      ),
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
        IconButton(
          onPressed: () {
            widget.tasksPageState.tasksListProvider.addEditorItem();
          },
          icon: Icon(
            Icons.add,
            color: Colors.white,
          ),
          tooltip: "New task",
        )
      ],
    );
  }
}
