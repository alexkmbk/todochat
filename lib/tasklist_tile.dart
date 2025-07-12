import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:pasteboard/pasteboard.dart";
import "package:provider/provider.dart";
import "package:todochat/constants.dart";
import "package:todochat/models/message.dart";
import "package:todochat/models/task.dart";
import "package:todochat/todochat.dart";
import "package:todochat/ui_components/context_menu_detector.dart";
import "package:todochat/ui_components/tile_menu.dart";
import "package:todochat/utils.dart";

import "customWidgets.dart";
import "highlight_text.dart";
import "state/tasks.dart";
import "tasklist.dart";
import 'state/msglist_provider.dart';

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
    final taskListProvider = Provider.of<TasksState>(context, listen: false);
    if (task.editMode) {
      taskListProvider.textEditingController =
          TextEditingController(text: task.description);
      return Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
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
                                  fillColor: Colors.white,
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
                                          tempTask.description.substring(0,
                                              tempTask.description.length - 1);
                                    }
                                    var res =
                                        await updateTask(context, tempTask);
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
            // if (task.previewSmallImageData != null)
            //   Image.memory(task.previewSmallImageData as Uint8List)
            // else
            if (task.fileName.isNotEmpty)
              DecoratedBox(
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
          Wrap(
            alignment: WrapAlignment.spaceAround,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(64,
                        30) // put the width and height you want, standard ones are 64, 40
                    ),
                // style: OutlinedButton.styleFrom(
                //   side: BorderSide(width: 1.0, color: Colors.blue),
                //   shape: const StadiumBorder(),
                // ),
                onPressed: taskListProvider.loading
                    ? null
                    : () async {
                        taskListProvider.saveEditingItem(context);
                      },
                child: RichText(
                  text: TextSpan(
                      text: "Save ",
                      style: TextStyle(color: Colors.blue),
                      children: [
                        if (isDesktopMode)
                          TextSpan(
                              text: "(Enter)",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold))
                      ]),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(64,
                        30) // put the width and height you want, standard ones are 64, 40
                    ),
                // style: OutlinedButton.styleFrom(
                //   side: BorderSide(width: 1.0, color: Colors.blue),
                //   shape: const StadiumBorder(),
                // ),
                onPressed: () {
                  taskListProvider.taskEditMode = false;
                  if (taskListProvider.isNewItem) {
                    taskListProvider.deleteEditorItem();
                  } else {
                    task.editMode = false;
                    taskListProvider.refresh();
                  }
                },
                child: RichText(
                  text: const TextSpan(
                    text: "Cancel ",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
        ]),
      );
    } else {
      return ContextMenuDetector(
        onContextMenu: (Offset position) {
          TileMenu.show(
            context: context,
            position: position,
            onDelete: () async {
              if (await taskListProvider.deleteTask(task.ID, context)) {
                taskListProvider.deleteItem(task.ID, context);
              }
            },
            onCopy: () {
              Pasteboard.writeText(task.description);
            },
            onEdit: () => onLongPress(task, taskListProvider),
          );
        },
        child: Material(
          child: ListTile(
            splashColor: Colors.transparent,
            horizontalTitleGap: 5,
            tileColor: getTileColor(
                taskListProvider.currentTask != null &&
                    taskListProvider.currentTask!.ID == task.ID,
                task),
            onTap: () => onTap(task, taskListProvider, context),
            leading: SizedBox(
              height: 10.0,
              width: 10.0,
              child: Checkbox(
                  checkColor: task.cancelled ? Colors.grey : null,
                  shape: const CircleBorder(),
                  fillColor: MaterialStateProperty.resolveWith((states) {
                    if (task.cancelled) {
                      return Colors.grey;
                    } else if (task.closed)
                      return Colors.green;
                    else
                      return null;
                  }),
                  value: task.closed,
                  onChanged: (value) => taskClosedOnChanged(
                      value, task, taskListProvider, context)),
            ),
            //title:
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                taskListProvider.searchMode
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
                if (task.lastMessage.isNotEmpty || task.unreadMessages > 0)
                  taskListProvider.searchMode
                      ? Row(
                          children: [
                            const SizedBox(width: 15),
                            Expanded(
                              child: HighlightText(
                                maxLines: 1,
                                leading: task.lastMessageUserName.isNotEmpty
                                    ? TextSpan(
                                        text: "${task.lastMessageUserName}: ",
                                        style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.blue))
                                    : null,
                                highlightColor: Colors.red,
                                text: task.lastMessage,
                                textStyle: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey),
                                words: taskListProvider.searchHighlightedWords,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(children: [
                                    if (task.lastMessageUserName.isNotEmpty)
                                      TextSpan(
                                          text: "${task.lastMessageUserName}: ",
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.blue)),
                                    TextSpan(
                                      text: task.lastMessage,
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey),
                                    ),
                                  ]),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (task.unreadMessages > 0)
                                NumberInStadium(number: task.unreadMessages),
                            ]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (task.inHand)
                      const Label(
                        text: "In Hand",
                        icon: Icon(Icons.handshake),
                        backgroundColor: inHandTaskColor,
                        textColor: Colors.green,
                      ),
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
                ),
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

  Future<void> onTap(
      Task task, TasksState taskListProvider, BuildContext context) async {
    bool refresh = false;

    if (task.read == false) {
      task.read = true;
      refresh = true;
    }
    if (task.unreadMessages != 0) {
      task.unreadMessages = 0;
      refresh = true;
    }
    refresh = taskListProvider.setCurrentTask(task, context) || refresh;

    if (!isDesktopMode) {
      openTask(context, task);
    }
    if (refresh) {
      taskListProvider.refresh();
    }
  }

  void onLongPress(Task task, TasksState taskListProvider) {
    var foundTask = taskListProvider.items
        .firstWhereOrNull((element) => element.ID == task.ID);
    if (foundTask != null) {
      foundTask.editMode = true;
      taskListProvider.isNewItem = false;
    }
    taskListProvider.refresh();
  }

  void taskClosedOnChanged(bool? value, Task task, TasksState TaskListProvider,
      BuildContext context) async {
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
