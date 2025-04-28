import 'package:flutter/material.dart';
import 'package:todochat/msglist_appbar.dart';
import 'msglist.dart';
import 'todochat.dart';

class TaskMessagesPage extends StatelessWidget {
  const TaskMessagesPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isDesktopMode) {
      return const MsgList();
    } else {
      return Scaffold(
          appBar: isDesktopMode ? null : const MessagesAppBar(),
          body: const Center(
            child: const MsgList(),
          ));
    }
  }
}
