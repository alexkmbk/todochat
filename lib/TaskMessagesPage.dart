import 'package:flutter/material.dart';
//import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:todochat/models/task.dart';
import 'package:todochat/state/tasks.dart';
import 'main_menu.dart';
import 'package:provider/provider.dart';
import 'msglist.dart';
import 'msglist_provider.dart';
import 'todochat.dart';

class TaskMessagesPage extends StatefulWidget {
  //final Task task;
  const TaskMessagesPage({
    Key? key,
  }) : super(key: key);

  @override
  State<TaskMessagesPage> createState() {
    return _TaskMessagesPageState();
  }
}

class _TaskMessagesPageState extends State<TaskMessagesPage> {
  AutoScrollController scrollController = AutoScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktopMode) {
      return Consumer<MsgListProvider>(builder: (context, provider, child) {
        return MsgList(
          scrollController: scrollController,
        );
      });
    } else {
      return Scaffold(
          appBar: isDesktopMode ? null : const MessagesAppBar(),
          body: Center(
            child: MsgList(scrollController: scrollController),
          ));
    }
  }
}

class MessagesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MessagesAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksState>();
    return AppBar(
      leading: const MainMenu(),
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
                  tasks.currentTask?.description ?? "",
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ))),
      ]),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => throw UnimplementedError();
}
