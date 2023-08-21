import 'package:flutter/material.dart';
import 'package:todochat/searchField.dart';
import 'package:todochat/tasklist_provider.dart';
import 'tasklist.dart';
import 'package:provider/provider.dart';
import 'main_menu.dart';
import 'TaskMessagesPage.dart';
import 'ProjectsList.dart';

import 'todochat.dart';
import 'package:multi_split_view/multi_split_view.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool showSearch = isDesktopMode;

  late FloatingActionButton floatingActionButton;

  @override
  void initState() {
    super.initState();
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
                body: Body(taskListProvider: provider),
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
}
//final msgListProvider = Provider.of<MsgListProvider>(context, listen: false);

// if (taskListProvider.currentTask != null) {
//   msgListProvider.taskID = taskListProvider.currentTask!.ID;
//   msgListProvider.task = taskListProvider.currentTask;
//   if (taskListProvider.searchMode) {
//     msgListProvider.foundMessageID =
//         taskListProvider.currentTask!.lastMessageID;
//   } else {
//     msgListProvider.foundMessageID = 0;
//   }
// }

// var currentTask = taskListProvider.currentTask;
// currentTask ??= Task(ID: 0);
// return TaskMessagesPage(
//   task: currentTask,
// );

class Body extends StatelessWidget {
  final TaskListProvider taskListProvider;
  const Body({required this.taskListProvider, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            children: [
              TaskList(taskListProvider: taskListProvider),
              TaskMessagesPage(
                task: taskListProvider.currentTask == null
                    ? Task(ID: 0)
                    : taskListProvider.currentTask as Task,
              ),
            ],
          ));
    } else {
      return Center(
        child: TaskList(taskListProvider: taskListProvider),
      );
    }
  }
}

class TasksPageAppBar extends StatefulWidget implements PreferredSizeWidget {
  final _TasksPageState tasksPageState;

  TasksPageAppBar({Key? key, required this.tasksPageState}) : super(key: key);

  @override
  State<TasksPageAppBar> createState() => _TasksPageAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TasksPageAppBarState extends State<TasksPageAppBar> {
  TextEditingController searchController = TextEditingController();
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
              taskListProvider.clear(context);
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

  Widget getAppBarTitle() {
    if (isDesktopMode) {
      return Row(children: [
        Flexible(
            fit: FlexFit.tight,
            flex: 4,
            child: SearchField(
              searchController: searchController,
            )),
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
      return SearchField(
        searchController: searchController,
      );
    } else {
      return getProjectField();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskListProvider =
        Provider.of<TaskListProvider>(context, listen: false);
    return AppBar(
      //toolbarHeight: 10, //MediaQuery.of(context).size.height * .1,
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
            child: Text(taskListProvider.showClosed
                ? "Hide completed"
                : "Show completed"),
            onTap: () async {
              taskListProvider.showClosed = !taskListProvider.showClosed;
              settings.setBool("showClosed", taskListProvider.showClosed);
              taskListProvider.clear(context);
              if (taskListProvider.search.isNotEmpty) {
                taskListProvider.searchTasks(taskListProvider.search, context);
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
