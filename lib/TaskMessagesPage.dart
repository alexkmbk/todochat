import 'package:flutter/material.dart';
import 'package:todochat/msglist_appbar.dart';
import 'msglist.dart';
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
  //AutoScrollController scrollController = AutoScrollController();

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
      return const MsgList();
    } else {
      return Scaffold(
          appBar: isDesktopMode ? null : const MessagesAppBar(),
          body: Center(
            child: const MsgList(),
          ));
    }
  }
}
