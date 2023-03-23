import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
//import 'package:todochat/TasksPage.dart';
import 'HttpClient.dart';
import 'LoginPage.dart';
import 'msglist.dart';
import 'TaskMessagesPage.dart';
import 'customWidgets.dart';
import 'highlight_text.dart';
import 'utils.dart';
import 'package:collection/collection.dart';
import 'ProjectsList.dart';
import 'todochat.dart';
import 'tasklist_provider.dart';
import 'tasklist_tile.dart';

import 'msglist_provider.dart';

//import 'package:badges/badges.dart';
import 'package:flutter_list_view/flutter_list_view.dart';

typedef RequestFn = Future<List<Task>> Function(TaskListProvider context);
typedef OnAddFn = Future<bool> Function(String description);
typedef OnDeleteFn = Future<bool> Function(int taskID);
typedef ItemBuilder = Widget Function(
    BuildContext context, Task item, int index);

class TaskList extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final ItemScrollController scrollController;

  const TaskList(
      {Key? key,
      required this.scrollController,
      required this.itemPositionsListener})
      : super(key: key);

  @override
  TaskListState createState() {
    return TaskListState();
  }
}

class TaskListState extends State<TaskList> {
  //late TaskListProvider _taskListProvider;
  bool loading = false;
  FlutterSliverListController flutterSliverListController =
      FlutterSliverListController();

  FlutterListViewController flutterListViewController =
      FlutterListViewController();
  @override
  void initState() {
    flutterListViewController.sliverController.onPaintItemPositionsCallback =
        (height, positions) {
      TaskListProvider taskListProvider =
          Provider.of<TaskListProvider>(context, listen: false);
      // height is widget's height
      // positions is the items which render in viewports
      if (positions.last.index >= taskListProvider.items.length - 12) {
        taskListProvider.requestTasks(context);
      }
      // for (var pos in positions) {
      //   // index is item index of list
      //   // offset is based on viewport
      //   print("index:${pos.index} offset:${pos.offset}");
      // }
    };

    super.initState();

    //_taskListProvider = Provider.of<TaskListProvider>(context, listen: false);
    //_msgListProvider = Provider.of<MsgListProvider>(context, listen: false);
  }

// This is what you're looking for!

  @override
  Widget build(BuildContext context) {
    final taskListProvider =
        Provider.of<TaskListProvider>(context, listen: false);
    return Column(children: <Widget>[
      Expanded(
          child: FlutterListView(
              controller: flutterListViewController,
              //padding: EdgeInsets.zero,
              //itemScrollController: widget.scrollController,
              //itemPositionsListener: widget.itemPositionsListener,
              //extraScrollSpeed: Platform().isAndroid || Platform().isIOS ? 0 : 40,
              //controller: widget.scrollController,
              delegate: FlutterListViewDelegate(
                (BuildContext context, int index) {
                  return TaskListTile(
                      index: index,
                      task: taskListProvider.items[index],
                      taskList: widget);
                  /*if (index < _taskListProvider.items.length) {
            return buildListRow(context, index, _taskListProvider.items[index],
                _taskListProvider, widget);
          }
          return const Center(child: Text('End of list'));*/
                },
                childCount: taskListProvider.items.length,
                //itemCount: taskListProvider.items.length,
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
