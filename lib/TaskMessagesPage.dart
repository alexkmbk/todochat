import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:todochat/tasklist_provider.dart';
import 'main_menu.dart';
import 'package:provider/provider.dart';
import 'msglist.dart';
import 'msglist_provider.dart';
import 'todochat.dart';

class TaskMessagesPage extends StatefulWidget {
  final Task task;
  const TaskMessagesPage({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskMessagesPage> createState() {
    return _TaskMessagesPageState();
  }
}

class _TaskMessagesPageState extends State<TaskMessagesPage> {
  FlutterListViewController flutterListViewController =
      FlutterListViewController();

  @override
  void initState() {
    super.initState();

    // final msgListProvider =
    //     Provider.of<MsgListProvider>(context, listen: false);
    // msgListProvider.taskID = widget.task.ID;
    // msgListProvider.task = widget.task;
    // msgListProvider.foundMessageID = widget.task.lastMessageID;
    // msgListProvider.scrollController = flutterListViewController;
    // final taskListProvider =
    //     Provider.of<TaskListProvider>(context, listen: false);
    // msgListProvider.requestMessages(taskListProvider, context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget drawBody() {
    return Consumer<MsgListProvider>(builder: (context, provider, child) {
      return MsgList(
        msglist: provider,
        flutterListViewController: flutterListViewController,
      );
    });
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
