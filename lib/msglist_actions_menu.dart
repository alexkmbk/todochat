import 'package:flutter/material.dart';
import 'package:todochat/tasklist_provider.dart';

import 'customWidgets.dart';
import 'msglist_provider.dart';

class ActionsMenu extends StatelessWidget {
  final MsgListProvider msglist;

  const ActionsMenu({Key? key, required this.msglist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final task = msglist.task as Task;

    List<PopupMenuItem> items = [
      if (!task.completed)
        PopupMenuItem(
            child: const Label(
              text: 'Done',
              backgroundColor: Colors.green,
              clickableCursor: true,
            ),
            onTap: () {
              msglist.createMessage(
                  text: "",
                  task: msglist.task,
                  messageAction: MessageAction.CompleteTaskAction);
              msglist.task.completed = true;
            }),
      if (task.completed)
        PopupMenuItem(
            child: const Text.rich(
                TextSpan(text: "Remove the ", children: <InlineSpan>[
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Label(
                  text: "Done",
                  backgroundColor: Colors.green,
                  clickableCursor: true,
                ),
              ),
              WidgetSpan(child: Text("label"))
            ])),
            onTap: () {
              msglist.createMessage(
                  text: "",
                  task: msglist.task,
                  messageAction: MessageAction.RemoveCompletedLabelAction);
              msglist.task.completed = false;
            }),
      if (!task.cancelled)
        PopupMenuItem(
            child: const Label(
              text: 'Cancel task',
              backgroundColor: Colors.grey,
              clickableCursor: true,
            ),
            onTap: () {
              msglist.createMessage(
                  text: "",
                  task: msglist.task,
                  messageAction: MessageAction.CancelTaskAction);
              msglist.task.cancelled = true;
            }),
      if (task.cancelled || task.closed)
        PopupMenuItem(
            child: const Label(
              text: 'Reopen task',
              backgroundColor: Colors.orange,
              clickableCursor: true,
            ),
            onTap: () {
              msglist.createMessage(
                  text: "",
                  task: msglist.task,
                  messageAction: MessageAction.ReopenTaskAction);
              msglist.task.cancelled = false;
              msglist.task.completed = false;
              msglist.task.closed = false;
            }),
    ];

    return PopupMenuButton(
      color: Colors.white,
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),

      // add icon, by default "3 dot" icon
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey[800],
      ),
      itemBuilder: (context) {
        return items;
      },
    );
  }
}

Widget getMessageActionDescription(Message message) {
  switch (message.messageAction) {
    case MessageAction.ReopenTaskAction:
      return Text.rich(TextSpan(text: "The task was ", children: <InlineSpan>[
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Label(
            text: "Reopened",
            backgroundColor: Colors.orange,
          ),
        ),
        const WidgetSpan(child: Text(" by ")),
        WidgetSpan(
            child: Text(message.userName,
                style: const TextStyle(color: Colors.blue))),
      ]));

    //'The task was reopen by ${message.userName}';
    case MessageAction.CancelTaskAction:
      return Text.rich(
          TextSpan(text: "The task was marked as ", children: <InlineSpan>[
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Label(
            text: "Cancelled",
            backgroundColor: Colors.grey,
          ),
        ),
        const WidgetSpan(child: Text(" by ")),
        WidgetSpan(
            child: Text(message.userName,
                style: const TextStyle(color: Colors.blue))),
      ]));
    case MessageAction.CompleteTaskAction:
      return Text.rich(
          TextSpan(text: "The task was marked as ", children: <InlineSpan>[
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Label(text: "Done", backgroundColor: Colors.green),
        ),
        const WidgetSpan(child: Text(" by ")),
        WidgetSpan(
            child: Text(message.userName,
                style: const TextStyle(color: Colors.blue))),
      ]));
    case MessageAction.CloseTaskAction:
      return Text.rich(TextSpan(text: "The task was ", children: <InlineSpan>[
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Label(
            text: "Closed",
            backgroundColor: Colors.green,
          ),
        ),
        const WidgetSpan(child: Text(" by ")),
        WidgetSpan(
            child: Text(message.userName,
                style: const TextStyle(color: Colors.blue))),
      ]));

    case MessageAction.RemoveCompletedLabelAction:
      return Text.rich(TextSpan(text: "The lable ", children: <InlineSpan>[
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Label(
            text: "Done",
            backgroundColor: Colors.green,
          ),
        ),
        const WidgetSpan(child: Text(" was removed by ")),
        WidgetSpan(
            child: Text(
          message.userName,
          style: const TextStyle(color: Colors.blue),
        )),
      ]));
    default:
      return const Text("");
  }
}
