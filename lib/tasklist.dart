import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
//import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';
//import 'package:scroll_to_index/scroll_to_index.dart';

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
  AutoScrollController scrollController = AutoScrollController();
  @override
  void initState() {
    // widget.taskListProvider.requestTasks(context);
    // scrollController.sliverController.onPaintItemPositionsCallback =
    //     (height, positions) {
    //   // height is widget's height
    //   // positions is the items which render in viewports
    //   if (positions.last.index >= widget.taskListProvider.items.length - 5) {
    //     widget.taskListProvider.requestTasks(context);
    //   }
    // };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var taskListProvider = widget.taskListProvider;
    taskListProvider.scrollController = scrollController;
    return Column(children: <Widget>[
      Expanded(
          child: InfiniteList(
              scrollController: scrollController,
              itemCount: taskListProvider.items.length,
              isLoading: taskListProvider.loading,
              onFetchData: () {
                taskListProvider.requestTasks(context);
              },
              itemBuilder: (context, index) {
                {
                  return AutoScrollTag(
                      key: ValueKey(index),
                      controller: scrollController,
                      index: index,
                      highlightColor: Colors.black.withOpacity(0.1),
                      child: TaskListTile(
                          index: index,
                          task: taskListProvider.items[index],
                          taskList: widget));
                }
              }))
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

void openTask(BuildContext context, Task task) async {
  final msgListProvider = Provider.of<MsgListProvider>(context, listen: false);

  msgListProvider.isOpen = true;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => TaskMessagesPage(task: task)),
  );
  if (!isDesktopMode) {
    msgListProvider.clear();
    msgListProvider.task = Task();
    msgListProvider.isOpen = false;
  }
}
