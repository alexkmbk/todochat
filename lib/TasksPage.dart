import 'package:flutter/material.dart';
import 'package:todochat/taskpage_appbar.dart';
import 'package:todochat/tasks_floating_button.dart';
import 'tasklist.dart';
import 'TaskMessagesPage.dart';
import 'todochat.dart';
import 'package:multi_split_view/multi_split_view.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final tasks = context.watch<TasksState>();
    // return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    //   Expanded(
    //       child:
    return Scaffold(
        appBar: TasksPageAppBar(),
        body: Body(),
        floatingActionButton:
            !isDesktopMode ? const TasksFloatingButton() : null);
    //)
    //]);
  }
}

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final settingsState = context.watch<SettingsState>();
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
            initialAreas: [
              Area(flex: 0.4, builder: (context, area) => const TaskList()),
              Area(builder: (context, area) => const TaskMessagesPage())
            ],
          ));
    } else {
      return Center(
        child: const TaskList(),
      );
    }
  }
}
