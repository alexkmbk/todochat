import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'HttpClient.dart';
import 'MsgList.dart';
import 'TaskMessagesPage.dart';
import 'customWidgets.dart';
import 'highlight_text.dart';
import 'utils.dart';
import 'package:collection/collection.dart';
import 'ProjectsList.dart';
import 'main.dart';

class TasksListProvider extends ChangeNotifier {
  Project? project;
  int? projectID;
  List<Task> items = [];
  int lastID = 0;
  DateTime? lastCreation_date;
  bool loading = false;
  bool searchMode = false;
  bool taskEditMode = false;
  List<String> searchHighlightedWords = [];
  Task? currentTask;

  void refresh() {
    notifyListeners();
  }

  void clear() {
    items.clear();
    lastID = 0;
    lastCreation_date = null;
    taskEditMode = false;
  }

  void setProjectID(int? value) {
    projectID = value;
    notifyListeners();
  }

  void addEditorItem() {
    items.insert(0, Task(editMode: true, isNewItem: true));
    notifyListeners();
  }

  void deleteEditorItem() {
    items.removeWhere((item) => item.editMode == true);
    taskEditMode = false;
    notifyListeners();
  }

  void addItem(Task task) {
    items.insert(0, task);
    notifyListeners();
  }

  void updateLastMessage(int taskID, Message message) {
    var item = items.firstWhereOrNull((element) => element.ID == taskID);
    if (item != null) {
      item.lastMessage = message.text;
      item.lastMessageID = message.ID;
      item.lastMessageUserName = message.userName;
      if (message.userID != currentUserID) {
        item.unreadMessages++;
      }
      notifyListeners();
    }
  }

  void deleteItem(int taskID) async {
    items.removeWhere((item) => item.ID == taskID);
    notifyListeners();
  }
}

class Task {
  int ID = 0;
  int projectID = 0;
  int authorID = 0;
  String authorName = "";
  bool Completed = false;
  String Description = "";
  String lastMessage = "";
  int lastMessageID = 0;
  bool editMode = false;
  DateTime Creation_date = DateTime.utc(0);
  bool isNewItem = false;
  bool read = false;
  int unreadMessages = 0;
  String lastMessageUserName = "";
  String fileName = "";
  int fileSize = 0;
  String localFileName = "";
  Uint8List? previewSmallImageData;

  Task(
      {this.ID = 0,
      this.Description = "",
      this.Completed = false,
      this.editMode = false,
      this.isNewItem = false});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'Completed': Completed,
      'Description': Description,
      'LastMessage': lastMessage,
      'LastMessageID': lastMessageID,
      'ProjectID': projectID,
      'AuthorID': authorID,
      'Creation_date': Creation_date.toIso8601String(),
      'AuthorName': authorName,
      'Read': read,
      'UnreadMessages': unreadMessages,
      'LastMessageUserName': lastMessageUserName,
      'FileName': fileName,
      'FileSize': fileSize,
      'LocalFileName': localFileName,
      'previewSmallImageBase64': toBase64(previewSmallImageData),
    };
  }

  Task.fromJson(Map<String, dynamic> json) {
    ID = json['ID'];
    Creation_date = DateTime.tryParse(json['Creation_date']) ?? DateTime.utc(0);
    Completed = json['Completed'];
    Description = json['Description'];
    lastMessage = json['LastMessage'];
    lastMessageID = json['LastMessageID'];
    projectID = json['ProjectID'];
    authorID = json['AuthorID'];
    authorName = json['AuthorName'];
    read = json['Read'];
    unreadMessages = json['UnreadMessages'];
    lastMessageUserName = json['LastMessageUserName'];
    /*fileName = json['FileName'];
    fileSize = json['FileSize'];
    localFileName = json['LocalFileName'];

    var previewSmallImageBase64 = json['PreviewSmallImageBase64'];
    if (previewSmallImageBase64 != null && previewSmallImageBase64 != "") {
      previewSmallImageData = fromBase64(previewSmallImageBase64);
    }*/
  }

  Task.from(Task task) {
    ID = task.ID;
    Description = task.Description;
    Creation_date = task.Creation_date;
    Completed = task.Completed;
    lastMessage = task.lastMessage;
    lastMessageID = task.lastMessageID;
    projectID = task.projectID;
    authorID = task.authorID;
    authorName = task.authorName;
    read = task.read;
    unreadMessages = task.unreadMessages;
    lastMessageUserName = task.lastMessageUserName;
    fileName = task.fileName;
    fileSize = task.fileSize;
    localFileName = task.localFileName;
    previewSmallImageData = task.previewSmallImageData;
  }
}

typedef RequestFn = Future<List<Task>> Function(TasksListProvider context);
typedef OnAddFn = Future<bool> Function(String description);
typedef OnDeleteFn = Future<bool> Function(int taskID);
typedef ItemBuilder = Widget Function(
    BuildContext context, Task item, int index);

class InifiniteTaskList extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final ItemScrollController scrollController;
  final OnAddFn onAddFn;
  final OnDeleteFn onDeleteFn;
  final MsgListProvider msgListProvider;

  const InifiniteTaskList(
      {Key? key,
      required this.scrollController,
      required this.itemPositionsListener,
      required this.onAddFn,
      required this.onDeleteFn,
      required this.msgListProvider})
      : super(key: key);

  @override
  InifiniteTaskListState createState() {
    return InifiniteTaskListState();
  }
}

class InifiniteTaskListState extends State<InifiniteTaskList> {
  late TasksListProvider _taskListProvider;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _taskListProvider = Provider.of<TasksListProvider>(context, listen: false);
    //_msgListProvider = Provider.of<MsgListProvider>(context, listen: false);
  }

// This is what you're looking for!

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(
          child: ScrollablePositionedList.builder(
        padding: EdgeInsets.zero,
        itemScrollController: widget.scrollController,
        itemPositionsListener: widget.itemPositionsListener,
        //controller: widget.scrollController,
        itemBuilder: (context, index) {
          return TaskListTile(
              index: index,
              task: _taskListProvider.items[index],
              tasksListProvider: _taskListProvider,
              inifiniteTaskList: widget,
              msgListProvider: widget.msgListProvider);
          /*if (index < _taskListProvider.items.length) {
            return buildListRow(context, index, _taskListProvider.items[index],
                _taskListProvider, widget);
          }
          return const Center(child: Text('End of list'));*/
        },
        itemCount: _taskListProvider.items.length,
      )),
    ]);
  }
}

class TaskListTile extends StatefulWidget {
  final int index;
  final Task task;
  final TasksListProvider tasksListProvider;
  final InifiniteTaskList inifiniteTaskList;
  final MsgListProvider msgListProvider;

  const TaskListTile(
      {Key? key,
      required this.index,
      required this.task,
      required this.tasksListProvider,
      required this.inifiniteTaskList,
      required this.msgListProvider})
      : super(key: key);

  @override
  State<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<TaskListTile> {
  var textEditingController = TextEditingController(text: "");
  @override
  Widget build(BuildContext context) {
    return buildListRow(context);
  }

  Color? getTileColor(bool selected) {
    if (isDesktopMode && selected) {
      return Colors.blue[50];
    }
    return null;
  }

  void onSave(String text) async {
    if (text.isNotEmpty) {
      if (widget.task.isNewItem) {
        await widget.inifiniteTaskList.onAddFn(text);
        widget.tasksListProvider.deleteEditorItem();
        widget.tasksListProvider.taskEditMode = false;
      } else {
        var tempTask = Task.from(widget.task);
        tempTask.Description = text;
        if (tempTask.Description.endsWith('\n')) {
          tempTask.Description = tempTask.Description.substring(
              0, tempTask.Description.length - 1);
        }
        var res = await updateTask(tempTask);
        if (res) {
          setState(() {
            widget.task.Description = tempTask.Description;
            widget.task.editMode = false;
            widget.tasksListProvider.taskEditMode = false;
          });
        }
      }
    }
  }

  Widget buildListRow(BuildContext context) {
    if (widget.task.editMode) {
      textEditingController =
          TextEditingController(text: widget.task.Description);
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
                              if (widget.task.isNewItem) {
                                widget.tasksListProvider.deleteEditorItem();
                              } else {
                                setState(() {
                                  widget.task.editMode = false;
                                });
                              }
                              FocusScope.of(context).unfocus();
                            },
                            const SingleActivator(LogicalKeyboardKey.enter,
                                control: true): () {
                              textEditingController.text =
                                  '${textEditingController.text}\n';
                              textEditingController.setCursorOnEnd();
                            },
                            const SingleActivator(LogicalKeyboardKey.enter,
                                control: false): () {
                              onSave(textEditingController.text.trim());
                            },
                          },
                          child: Focus(
                            onFocusChange: (hasFocus) {
                              /*  if (!hasFocus) {
                              if (widget.task.isNewItem) {
                                widget.tasksListProvider.deleteEditorItem();
                              } else {
                                setState(() {
                                  widget.task.editMode = false;
                                });
                              }
                            }*/
                            },
                            child: TextField(
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                controller: textEditingController,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: widget.task.isNewItem
                                        ? "New task name"
                                        : null),
                                autofocus: true,
                                textInputAction: TextInputAction.newline,
                                onSubmitted: (value) async {
                                  if (value.isNotEmpty) {
                                    if (widget.task.isNewItem) {
                                      await widget.inifiniteTaskList
                                          .onAddFn(value);
                                      widget.tasksListProvider
                                          .deleteEditorItem();
                                    } else {
                                      var tempTask = Task.from(widget.task);
                                      tempTask.Description = value;
                                      if (tempTask.Description.endsWith('\n')) {
                                        tempTask.Description =
                                            tempTask.Description.substring(
                                                0,
                                                tempTask.Description.length -
                                                    1);
                                      }
                                      var res = await updateTask(tempTask);
                                      if (res) {
                                        setState(() {
                                          widget.task.Description =
                                              tempTask.Description;
                                          widget.task.editMode = false;
                                        });
                                      }
                                    }
                                  }
                                }),
                          )))),
            ]),
            if (widget.task.fileSize > 0) ...[
              const Expanded(child: Divider()),
              if (widget.task.previewSmallImageData != null)
                Image.memory(widget.task.previewSmallImageData as Uint8List)
              else if (widget.task.fileName.isNotEmpty)
                DecoratedBox(
                    // chat bubble decoration
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GestureDetector(
                      //onTap: () => onTapOnFileMessage(widget.task, context),
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
                                      widget.task.fileName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText1!
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
                  onPressed: () async {
                    onSave(textEditingController.text.trim());
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
                    widget.tasksListProvider.taskEditMode = false;
                    if (widget.task.isNewItem) {
                      widget.tasksListProvider.deleteEditorItem();
                    } else {
                      setState(() {
                        widget.task.editMode = false;
                      });
                    }
                  },
                  child: const Text("Cancel"))
            ]),
          ]));
    } else {
      return Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) {
          return confirmDimissDlg(
              "Are you sure you wish to delete this item?", context);
        },
        onDismissed: (direction) async {
          if (await widget.inifiniteTaskList.onDeleteFn(widget.task.ID)) {
            widget.tasksListProvider.deleteItem(widget.task.ID);
          }
        },
        child: Card(
          color: widget.task.Completed
              ? completedTaskColor
              : widget.task.read
                  ? uncompletedTaskColor
                  : const Color.fromARGB(255, 250, 161, 27),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          child: ListTile(
              tileColor: widget.tasksListProvider.currentTask == null
                  ? null
                  : getTileColor(widget.tasksListProvider.currentTask!.ID ==
                      widget.task.ID),
              onTap: () => onTap(widget.task),
              onLongPress: () => onLongPress(widget.task),
              leading: Checkbox(
                  shape: const CircleBorder(),
                  fillColor: MaterialStateProperty.all(Colors.green),
                  value: widget.task.Completed,
                  onChanged: (value) =>
                      taskCompletedOnChanged(value, widget.task)),
              title: widget.tasksListProvider.searchMode
                  ? HighlightText(
                      highlightColor: Colors.red,
                      text: widget.task.Description,
                      words: widget.tasksListProvider.searchHighlightedWords,
                      maxLines: 5,
                    )
                  : Text(
                      widget.task.Description,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 5,
                    ),
              subtitle: widget.task.lastMessage.isEmpty
                  ? null
                  : widget.tasksListProvider.searchMode
                      ? HighlightText(
                          leading: widget.task.lastMessageUserName.isNotEmpty
                              ? TextSpan(
                                  text: "${widget.task.lastMessageUserName}: ",
                                  style: const TextStyle(color: Colors.blue))
                              : null,
                          highlightColor: Colors.red,
                          text: widget.task.lastMessage,
                          words:
                              widget.tasksListProvider.searchHighlightedWords,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Expanded(
                                  child: Text.rich(
                                TextSpan(children: [
                                  if (widget
                                      .task.lastMessageUserName.isNotEmpty)
                                    TextSpan(
                                        text:
                                            "${widget.task.lastMessageUserName}: ",
                                        style: const TextStyle(
                                            color: Colors.blue)),
                                  TextSpan(text: widget.task.lastMessage)
                                ]),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )),
                              if (widget.task.unreadMessages > 0)
                                Container(
                                    padding: const EdgeInsets.only(
                                        left: 5, right: 5),
                                    decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        )),
                                    child: Center(
                                        child: Text(
                                      widget.task.unreadMessages.toString(),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ))),
                            ])),
        ),
      );
    }
  }

  Future<void> onTap(Task task) async {
    if (isDesktopMode) {
      if (sessionID == "" || !mounted) {
        return;
      }
      widget.msgListProvider.clear(true);
      task.read = true;
      task.unreadMessages = 0;
      widget.tasksListProvider.currentTask = task;
      widget.tasksListProvider.refresh();
      widget.msgListProvider.taskID = task.ID;
      widget.msgListProvider.task = task;
      widget.msgListProvider.loading = true;
      widget.msgListProvider.requestMessages();
      /*ws!.sink.add(jsonEncode({
        "sessionID": sessionID,
        "command": "getMessages",
        "lastID": widget.msgListProvider.lastID.toString(),
        "messageIDPosition": task.lastMessageID.toString(),
        "limit": "30",
        "taskID": widget.msgListProvider.taskID.toString(),
      }));*/

      /*setState(() {
        msgListProvider.clear();
        tasksListProvider.currentTask = task;
      });*/
    } else {
      openTask(context, task, widget.msgListProvider);
      setState(() {
        task.read = true;
        task.unreadMessages = 0;
      });
    }
  }

  void onLongPress(Task task) {
    setState(() {
      var foundTask = widget.tasksListProvider.items
          .firstWhereOrNull((element) => element.ID == task.ID);
      if (foundTask != null) {
        foundTask.editMode = true;
        foundTask.isNewItem = false;
      }
    });
  }

  void taskCompletedOnChanged(bool? value, Task task) async {
    if (value == null) return;

    setState(() {
      task.Completed = value;
    });

    var res = await updateTask(Task.from(task)..Completed = value);

    if (!res) {
      setState(() {
        task.Completed = !value;
      });
    }
  }
}

Future<bool> updateTask(Task task) async {
  if (sessionID == "") {
    return false;
  }

  Response response;

  try {
    response = await httpClient.post(
        setUriProperty(serverURI, path: 'updateTask'),
        body: jsonEncode(task));
  } catch (e) {
    RestartWidget.restartApp();
    return false;
  }

  if (response.statusCode == 200) {
    return true;
  }

  return false;
}

void openTask(
    BuildContext context, Task task, MsgListProvider msgListProvider) {
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) => TaskMessagesPage(
              task: task,
              msgListProvider: msgListProvider,
            )),
  );
}
