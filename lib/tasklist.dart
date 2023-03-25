import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_list_view/flutter_list_view.dart';

import 'HttpClient.dart';
import 'TaskMessagesPage.dart';
import 'customWidgets.dart';
import 'todochat.dart';
import 'tasklist_provider.dart';
import 'tasklist_tile.dart';
import 'msglist_provider.dart';

class TaskList extends StatefulWidget {
  final TaskListProvider taskListProvider;
  const TaskList({Key? key, required this.taskListProvider}) : super(key: key);

  @override
  TaskListState createState() {
    return TaskListState();
  }
}

class TaskListState extends State<TaskList> {
  bool loading = false;
  FlutterListViewController flutterListViewController =
      FlutterListViewController();
  @override
  void initState() {
    flutterListViewController.sliverController.onPaintItemPositionsCallback =
        (height, positions) {
      // height is widget's height
      // positions is the items which render in viewports
      if (positions.last.index >= widget.taskListProvider.items.length - 5) {
        widget.taskListProvider.requestTasks(context);
      }
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(
          child: FlutterListView(
              controller: flutterListViewController,
              delegate: FlutterListViewDelegate(
                (BuildContext context, int index) {
                  return TaskListTile(
                      index: index,
                      task: widget.taskListProvider.items[index],
                      taskList: widget);
                },
                childCount: widget.taskListProvider.items.length,
              ))),
    ]);
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
    RestartWidget.restartApp();
    return false;
  }

  if (response.statusCode == 200) {
    return true;
  }

  return false;
}

void openTask(
    BuildContext context, Task task, MsgListProvider msgListProvider) async {
  msgListProvider.isOpen = true;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => TaskMessagesPage(task: task)),
  );
  if (!isDesktopMode) {
    msgListProvider.clear();
    msgListProvider.task = null;
    msgListProvider.taskID = 0;
    msgListProvider.isOpen = false;
  }
}
