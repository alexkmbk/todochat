import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'main_menu.dart';
import 'package:provider/provider.dart';
import 'msglist.dart';
import 'state/msglist_provider.dart';
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
      return MsgList(
        scrollController: scrollController,
      );
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
    final task = context.watch<MsgListProvider>().task;
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
                  task.description,
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ))),
      ]),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
