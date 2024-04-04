import 'package:flutter/material.dart';
import 'package:todochat/models/task.dart';
import 'package:todochat/state/tasks.dart';
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

  Widget floatingActionButtonToSave(TasksState provider, BuildContext context) {
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
    final tasks = context.read<TasksState>();
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(
          child: Scaffold(
              appBar: const TasksPageAppBar(),
              body: const Body(),
              floatingActionButton: !isDesktopMode
                  ? tasks.taskEditMode
                      ? floatingActionButtonToSave(tasks, context)
                      : FloatingActionButton(
                          onPressed: () {
                            if (!tasks.taskEditMode) {
                              tasks.addEditorItem();
                            }
                          },
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                        )
                  : null))
    ]);
  }
}

class Body extends StatelessWidget {
  //final TasksState taskListProvider;
  const Body({Key? key}) : super(key: key);

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
              const TaskList(),
              const TaskMessagesPage(),
            ],
          ));
    } else {
      return Center(
        child: const TaskList(),
      );
    }
  }
}
