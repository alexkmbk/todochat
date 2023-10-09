import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:pasteboard/pasteboard.dart";
import "package:provider/provider.dart";
import "package:todochat/todochat.dart";
import "package:todochat/utils.dart";

import "customWidgets.dart";
import "highlight_text.dart";
import "tasklist_provider.dart";
import "tasklist.dart";
import 'msglist_provider.dart';

class TaskListTile extends StatelessWidget {
  final int index;
  final Task task;
  final TaskList taskList;

  const TaskListTile(
      {Key? key,
      required this.index,
      required this.task,
      required this.taskList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskListProvider =
        Provider.of<TaskListProvider>(context, listen: false);
    if (task.editMode) {
      taskListProvider.textEditingController =
          TextEditingController(text: task.description);
      return Card(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.escape,
                                control: false): () {
                              if (taskListProvider.isNewItem) {
                                taskListProvider.deleteEditorItem();
                              } else {
                                task.editMode = false;
                                taskListProvider.refresh();
                              }
                              FocusScope.of(context).unfocus();
                            },
                            const SingleActivator(LogicalKeyboardKey.enter,
                                control: true): () {
                              taskListProvider.textEditingController.text =
                                  '${taskListProvider.textEditingController.text}\n';
                              taskListProvider.textEditingController
                                  .setCursorOnEnd();
                            },
                            const SingleActivator(LogicalKeyboardKey.enter,
                                control: false): () {
                              taskListProvider.saveEditingItem(context);
                            },
                          },
                          child: Focus(
                            onFocusChange: (hasFocus) {
                              /*  if (!hasFocus) {
                              if (task.isNewItem) {
                                taskListProvider.deleteEditorItem();
                              } else {
                                setState(() {
                                  task.editMode = false;
                                });
                              }
                            }*/
                            },
                            child: TextField(
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                controller:
                                    taskListProvider.textEditingController,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: taskListProvider.isNewItem
                                        ? "New task name"
                                        : null),
                                autofocus: true,
                                textInputAction: TextInputAction.newline,
                                onSubmitted: (value) async {
                                  if (value.isNotEmpty) {
                                    if (taskListProvider.isNewItem) {
                                      await taskListProvider.onAddTask(
                                          value, context);
                                      taskListProvider.deleteEditorItem();
                                    } else {
                                      var tempTask = Task.from(task);
                                      tempTask.description = value;
                                      if (tempTask.description.endsWith('\n')) {
                                        tempTask.description =
                                            tempTask.description.substring(
                                                0,
                                                tempTask.description.length -
                                                    1);
                                      }
                                      var res = await updateTask(tempTask);
                                      if (res) {
                                        task.description = tempTask.description;
                                        task.editMode = false;
                                        taskListProvider.refresh();
                                      }
                                    }
                                  }
                                }),
                          )))),
            ]),
            if (task.fileSize > 0) ...[
              const Expanded(child: Divider()),
              if (task.previewSmallImageData != null)
                Image.memory(task.previewSmallImageData as Uint8List)
              else if (task.fileName.isNotEmpty)
                DecoratedBox(
                    // chat bubble decoration
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GestureDetector(
                      //onTap: () => onTapOnFileMessage(task, context),
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.file_present_rounded,
                                    color: Colors.white),
                                const SizedBox(width: 10),
                                FittedBox(
                                    fit: BoxFit.fill,
                                    alignment: Alignment.center,
                                    child: SelectableText(
                                      task.fileName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(color: Colors.white),
                                    )),
                              ])),
                    )),
            ],
            Wrap(alignment: WrapAlignment.spaceAround, children: [
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                  ),
                  onPressed: taskListProvider.loading
                      ? null
                      : () async {
                          taskListProvider.saveEditingItem(context);
                        },
                  child: isDesktopMode
                      ? RichText(
                          text: const TextSpan(
                              text: "Save ",
                              style: TextStyle(color: Colors.blue),
                              children: [
                              TextSpan(
                                  text: "(Enter)",
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold))
                            ]))
                      : const Text("Save")),
              const SizedBox(width: 10),
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    taskListProvider.taskEditMode = false;
                    if (taskListProvider.isNewItem) {
                      taskListProvider.deleteEditorItem();
                    } else {
                      task.editMode = false;
                      taskListProvider.refresh();
                    }
                  },
                  child: const Text("Cancel"))
            ]),
          ]));
    } else {
      return GestureDetectorWithMenu(
        onDelete: () async {
          if (await taskListProvider.deleteTask(task.ID, context)) {
            taskListProvider.deleteItem(task.ID, context);
          }
        },
        onCopy: () {
          Pasteboard.writeText(task.description);
        },
        onEdit: () => onLongPress(task, taskListProvider),
        child: Material(
          child: ListTile(
            horizontalTitleGap: 0,
            tileColor: getTileColor(
                taskListProvider.currentTask != null &&
                    taskListProvider.currentTask!.ID == task.ID,
                task),
            onTap: () => onTap(task, taskListProvider, context),
            leading: Checkbox(
                checkColor: task.cancelled ? Colors.grey : null,
                shape: const CircleBorder(),
                fillColor: MaterialStateProperty.all(
                    task.cancelled ? Colors.grey : Colors.green),
                value: task.closed,
                onChanged: (value) => taskClosedOnChanged(
                    value, task, taskListProvider, context)),
            title: taskListProvider.searchMode
                ? HighlightText(
                    highlightColor: Colors.red,
                    text: task.description,
                    words: taskListProvider.searchHighlightedWords,
                    maxLines: 5,
                  )
                : Text(
                    task.description,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    style: task.cancelled
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontStyle: FontStyle.italic)
                        : null,
                    textAlign: TextAlign.left,
                  ),
            subtitle: Column(
              children: [
                if (task.lastMessage.isNotEmpty || task.unreadMessages > 0)
                  taskListProvider.searchMode
                      ? HighlightText(
                          leading: task.lastMessageUserName.isNotEmpty
                              ? TextSpan(
                                  text: "${task.lastMessageUserName}: ",
                                  style: const TextStyle(color: Colors.blue))
                              : null,
                          highlightColor: Colors.red,
                          text: task.lastMessage,
                          words: taskListProvider.searchHighlightedWords,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Expanded(
                                  child: Text.rich(
                                TextSpan(children: [
                                  if (task.lastMessageUserName.isNotEmpty)
                                    TextSpan(
                                        text: "${task.lastMessageUserName}: ",
                                        style: const TextStyle(
                                            color: Colors.blue)),
                                  TextSpan(text: task.lastMessage)
                                ]),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )),
                              if (task.unreadMessages > 0)
                                NumberInStadium(number: task.unreadMessages),
                            ]),
                Row(
                  children: [
                    const Spacer(),
                    if (task.completed)
                      const Label(
                        text: "Done",
                        backgroundColor: Colors.green,
                      ),
                    if (task.cancelled)
                      const Label(
                        text: "Cancelled",
                        backgroundColor: Colors.grey,
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
      //);
    }
  }

  Color? getTileColor(bool selected, Task task) {
    if (isDesktopMode && selected) {
      return Colors.blue[50];
    } else if (task.cancelled) {
      return const Color.fromARGB(255, 228, 232, 233);
    }
    return task.closed
        ? closedTaskColor
        : task.read
            ? uncompletedTaskColor
            : const Color.fromARGB(255, 250, 161, 27);
  }

  Future<void> onTap(Task task, TaskListProvider taskListProvider,
      BuildContext context) async {
    // msgListProvider.clear(true);
    // msgListProvider.taskID = task.ID;
    // msgListProvider.task = task;

    task.read = true;
    task.unreadMessages = 0;

    if (isDesktopMode) {
      taskListProvider.setCurrentTask(task, context);
    } else {
      openTask(context, task);
    }
    taskListProvider.refresh();
  }

  void onLongPress(Task task, TaskListProvider taskListProvider) {
    var foundTask = taskListProvider.items
        .firstWhereOrNull((element) => element.ID == task.ID);
    if (foundTask != null) {
      foundTask.editMode = true;
      taskListProvider.isNewItem = false;
    }
    taskListProvider.refresh();
  }

  void taskClosedOnChanged(bool? value, Task task,
      TaskListProvider TaskListProvider, BuildContext context) async {
    if (value == null) return;

    task.closed = value;
    TaskListProvider.refresh();

    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    final res = await msgListProvider.createMessage(
        text: "",
        task: task,
        messageAction: value
            ? MessageAction.CloseTaskAction
            : MessageAction.ReopenTaskAction);
    if (res) {
      if (!TaskListProvider.showClosed) {
        if (task.closed) {
          TaskListProvider.deleteItem(task.ID, context);
        }
      }
    } else {
      task.closed = !value;
      TaskListProvider.refresh();
    }
  }
}
