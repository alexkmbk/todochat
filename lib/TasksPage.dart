import 'package:flutter/material.dart';
import 'package:todochat/tasklist_provider.dart';
import 'package:todochat/taskpage_appbar.dart';
import 'tasklist.dart';
import 'package:provider/provider.dart';
import 'TaskMessagesPage.dart';
import 'todochat.dart';
import 'package:multi_split_view/multi_split_view.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
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
    return Consumer<TaskListProvider>(
      builder: (context, provider, child) {
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
              child: Scaffold(
                  appBar: TasksPageAppBar(),
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
      },
    );
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
