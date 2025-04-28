import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:todochat/models/task.dart';
import 'package:todochat/state/settings.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';
import 'HttpClient.dart';
import 'TaskMessagesPage.dart';
import 'todochat.dart';
import 'state/tasks.dart';
import 'tasklist_tile.dart';
import 'state/msglist_provider.dart';

class TaskList extends StatefulWidget {
  const TaskList({Key? key}) : super(key: key);

  @override
  TaskListState createState() {
    return TaskListState();
  }
}

class TaskListState extends State<TaskList> {
  final AutoScrollController scrollController = AutoScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(
        child: Consumer<TasksState>(
          builder: (context, provider, child) {
            provider.scrollController = scrollController;
            return InfiniteList(
              scrollController: scrollController,
              itemCount: provider.items.length,
              isLoading: provider.loading,
              separatorBuilder: (context, index) => const Divider(
                height: 0.0,
                thickness: 0.0,
              ),
              onFetchData: () {
                provider.requestTasks(context);
              },
              itemBuilder: (context, index) {
                {
                  return AutoScrollTag(
                      key: ValueKey(index),
                      controller: scrollController,
                      index: index,
                      highlightColor: Colors.black.withValues(alpha: 0.1),
                      child: TaskListTile(
                          index: index,
                          task: provider.items[index],
                          taskList: widget));
                }
              },
            );
          },
        ),
      )
    ]);
  }
}

Future<bool> updateTask(BuildContext context, Task task) async {
  if (sessionID == "") {
    return false;
  }

  Response response;

  try {
    response = await httpClient.post(
        setUriProperty(serverURI, path: 'updateTask'),
        body: jsonEncode(task));
  } catch (e) {
    context.read<SettingsState>().redrawWidgetTree(context);
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
  msgListProvider.task = task;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const TaskMessagesPage()),
  );
  if (!isDesktopMode) {
    msgListProvider.clear();
    msgListProvider.task = Task();
    msgListProvider.isOpen = false;
  }
}
