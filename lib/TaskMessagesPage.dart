//import 'dart:typed_data';

import 'package:flutter/material.dart';
//import 'package:http/http.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
//import 'HttpClient.dart' as HTTPClient;
import 'MainMenu.dart';
//import 'utils.dart';
import 'package:provider/provider.dart';
import 'MsgList.dart';
import 'todochat.dart';
//import 'dart:io';
import 'inifiniteTaskList.dart';
//import 'package:progress_dialog/progress_dialog.dart';

//import 'package:web_socket_channel/web_socket_channel.dart';
//import 'package:web_socket_channel/status.dart' as status;

class TaskMessagesPage extends StatefulWidget {
  final Task task;
  const TaskMessagesPage({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskMessagesPage> createState() {
    return _TaskMessagesPageState();
  }
}

class _TaskMessagesPageState extends State<TaskMessagesPage> {
  final ItemScrollController itemsScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();

    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    msgListProvider.taskID = widget.task.ID;
    msgListProvider.task = widget.task;
    msgListProvider.foundMessageID = widget.task.lastMessageID;
    msgListProvider.scrollController = itemsScrollController;
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);
    msgListProvider.requestMessages(taskListProvider, context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget drawBody() {
    return /*Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [*/
        Consumer<MsgListProvider>(builder: (context, provider, child) {
      return NotificationListener<ScrollUpdateNotification>(
        child: InifiniteMsgList(
          scrollController: itemsScrollController,
          itemPositionsListener: itemPositionsListener,
        ),
        onNotification: (notification) {
          if (!provider.loading &&
              (itemPositionsListener.itemPositions.value.isEmpty ||
                  (itemPositionsListener.itemPositions.value.last.index >=
                      provider.items.length - 10))) {
            final taskListProvider =
                Provider.of<TasksListProvider>(context, listen: false);
            provider.requestMessages(taskListProvider, context);
          }
          return true;
        },
      );
    });
    //],
    //);
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktopMode) {
      return drawBody();
    } else {
      return Scaffold(
        appBar: isDesktopMode
            ? null
            : AppBar(
                backgroundColor: const Color.fromARGB(240, 255, 255, 255),
                title: Row(children: [
                  Flexible(
                      child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.keyboard_arrow_left,
                            color: Colors.black,
                          ),
                          label: Text(
                            widget.task.description,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ))),
                ]),
                leading: const MainMenu()),
        body: Center(child: drawBody()),
      );
    }
  }
}
