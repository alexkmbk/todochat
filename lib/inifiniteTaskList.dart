import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:todochat/TasksPage.dart';
import 'HttpClient.dart';
import 'LoginPage.dart';
import 'MsgList.dart';
import 'TaskMessagesPage.dart';
import 'customWidgets.dart';
import 'highlight_text.dart';
import 'utils.dart';
import 'package:collection/collection.dart';
import 'ProjectsList.dart';
import 'main.dart';
import 'package:badges/badges.dart';

class TasksListProvider extends ChangeNotifier {
  Project? project;
  int? projectID;
  List<Task> items = [];
  int lastID = 0;
  DateTime? lastCreation_date;
  bool loading = false;
  bool uploading = false;
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
    if (task.projectID == projectID) {
      if (items.firstWhereOrNull((element) => element.ID == task.ID) == null) {
        if (task.authorID == currentUserID) {
          task.read = true;
        }
        items.insert(0, task);
        notifyListeners();
      }
    }
  }

  void addItems(dynamic data) {
    bool notify = false;
    for (var item in data) {
      var task = Task.fromJson(item);
      if (task.projectID == projectID) {
        /*if (message.tempID.isNotEmpty) {
          final res = uploadingFiles[message.tempID];
          if (res != null && res.loadingFileData.isNotEmpty) {
            message.loadingFileData = res.loadingFileData;
          }
        }*/
        if (items.firstWhereOrNull((element) => element.ID == task.ID) ==
            null) {
          items.add(task);
          notify = true;
        }
      }
    }
    loading = false;
    if (data.length > 0) {
      lastID = data[data.length - 1]["ID"];
    }
    if (notify) {
      notifyListeners();
    }
  }

  void updateLastMessage(int taskID, Message message, [bool created = true]) {
    if (message.loadinInProcess) {
      return;
    }
    var item = items.firstWhereOrNull((element) => element.ID == taskID);
    if (item != null) {
      if (item.lastMessageID != message.ID &&
          message.userID != currentUserID &&
          !created) {
        items[items.indexOf(item)].unreadMessages++;
      }
      item.lastMessage = message.text;
      item.lastMessageID = message.ID;
      item.lastMessageUserName = message.userName;

      switch (message.messageAction) {
        case MessageAction.ReopenTaskAction:
          item.cancelled = false;
          item.closed = false;
          break;
        case MessageAction.CancelTaskAction:
          item.cancelled = true;
          break;
        case MessageAction.CompleteTaskAction:
          item.completed = true;
          break;
        case MessageAction.CloseTaskAction:
          item.closed = true;
          break;
        case MessageAction.RemoveCompletedLabelAction:
          item.completed = false;
          break;

        default:
      }
      notifyListeners();
    }
  }

  void deleteItem(int taskID, BuildContext context) async {
    var index = items.indexWhere((item) => item.ID == taskID);
    if (index >= 0) {
      items.removeAt(index);

      if (items.isEmpty) {
        clear();
        refresh();
      } else {
        if (index >= items.length) {
          index = items.length - 1;
        }
      }
      currentTask = items[index];
      final msgListProvider =
          Provider.of<MsgListProvider>(context, listen: false);
      msgListProvider.clear();
      msgListProvider.taskID = currentTask!.ID;
      msgListProvider.task = currentTask;
      msgListProvider.requestMessages();
      msgListProvider.refresh();
      notifyListeners();
    }
  }

  void updateItem(Task task) async {
    var item = items.firstWhereOrNull((element) => element.ID == task.ID);
    if (item != null) {
      items[items.indexOf(item)] = task;
      notifyListeners();
    }
  }

  Future<void> requestTasks(BuildContext context,
      [bool forceRefresh = false]) async {
    List<Task> res = [];

    if (sessionID == "") {
      return;
    }

    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    loading = true;

    var url = setUriProperty(serverURI, path: 'tasks', queryParameters: {
      "ProjectID": projectID.toString(),
      "lastID": lastID.toString(),
      "lastCreation_date": lastCreation_date.toString(),
      "limit": "25",
    });

    Response response;
    try {
      //response = await httpClient.get(url, headers: {"sessionID": sessionID});
      response = await httpClient.get(url);
    } catch (e) {
      return;
    }

    if (response.statusCode == 200 && response.body != "") {
      var data = jsonDecode(response.body);

      var tasks = data["tasks"];

      if (tasks == null) return;

      if (tasks.length > 0) {
        var lastItem = tasks[tasks.length - 1];
        lastID = lastItem["ID"];
        lastCreation_date = DateTime.tryParse(lastItem["Creation_date"]);

        for (var item in tasks) {
          res.add(Task.fromJson(item));
        }

        if (currentTask == null || currentTask!.projectID != projectID) {
          currentTask = Task.fromJson(tasks[0]);
          res[0].read = true;
          res[0].unreadMessages = 0;
          msgListProvider.task = currentTask;
          msgListProvider.taskID = msgListProvider.task?.ID ?? 0;
          msgListProvider.clear();
          if (isDesktopMode) {
            msgListProvider.requestMessages();
          }
        }
      } else if (items.isEmpty) {
        currentTask == null;
        msgListProvider.clear(true);
      }
    } else if (response.statusCode == 401) {
      bool result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    loading = false;

    if (res.isNotEmpty || forceRefresh) {
      items = [...items, ...res];
      refresh();
    }
  }
}

class Task {
  int ID = 0;
  int projectID = 0;
  int authorID = 0;
  String authorName = "";
  bool completed = false;
  bool cancelled = false;
  bool closed = false;

  String description = "";
  String lastMessage = "";
  int lastMessageID = 0;
  bool editMode = false;
  DateTime creation_date = DateTime.utc(0);
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
      this.description = "",
      this.completed = false,
      this.editMode = false,
      this.isNewItem = false});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'Completed': completed,
      'Cancelled': cancelled,
      'Closed': closed,
      'Description': description,
      'LastMessage': lastMessage,
      'LastMessageID': lastMessageID,
      'ProjectID': projectID,
      'AuthorID': authorID,
      'Creation_date': creation_date.toIso8601String(),
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
    creation_date = DateTime.tryParse(json['Creation_date']) ?? DateTime.utc(0);
    completed = json['Completed'];
    cancelled = json['Cancelled'];
    closed = json['Closed'];
    description = json['Description'];
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
    description = task.description;
    creation_date = task.creation_date;
    completed = task.completed;
    cancelled = task.cancelled;
    closed = task.closed;
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

  const InifiniteTaskList(
      {Key? key,
      required this.scrollController,
      required this.itemPositionsListener,
      required this.onAddFn,
      required this.onDeleteFn})
      : super(key: key);

  @override
  InifiniteTaskListState createState() {
    return InifiniteTaskListState();
  }
}

class InifiniteTaskListState extends State<InifiniteTaskList> {
  //late TasksListProvider _taskListProvider;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    //_taskListProvider = Provider.of<TasksListProvider>(context, listen: false);
    //_msgListProvider = Provider.of<MsgListProvider>(context, listen: false);
  }

// This is what you're looking for!

  @override
  Widget build(BuildContext context) {
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);
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
              task: taskListProvider.items[index],
              //tasksListProvider: taskListProvider,
              inifiniteTaskList: widget);
          /*if (index < _taskListProvider.items.length) {
            return buildListRow(context, index, _taskListProvider.items[index],
                _taskListProvider, widget);
          }
          return const Center(child: Text('End of list'));*/
        },
        itemCount: taskListProvider.items.length,
      )),
    ]);
  }
}

class TaskListTile extends StatefulWidget {
  final int index;
  final Task task;
  //final TasksListProvider tasksListProvider;
  final InifiniteTaskList inifiniteTaskList;

  const TaskListTile(
      {Key? key,
      required this.index,
      required this.task,
      //required this.tasksListProvider,
      required this.inifiniteTaskList})
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
    } else if (widget.task.cancelled) {
      return const Color.fromARGB(255, 228, 232, 233);
    }
    return widget.task.closed
        ? closedTaskColor
        : widget.task.read
            ? uncompletedTaskColor
            : const Color.fromARGB(255, 250, 161, 27);
  }

  void onSave(String text) async {
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);

    if (taskListProvider.loading) {
      return;
    }

    if (text.isNotEmpty) {
      if (widget.task.isNewItem) {
        final res = await widget.inifiniteTaskList.onAddFn(text);
        if (res) {
          taskListProvider.deleteEditorItem();
          taskListProvider.taskEditMode = false;
        }
      } else {
        var tempTask = Task.from(widget.task);
        tempTask.description = text;
        if (tempTask.description.endsWith('\n')) {
          tempTask.description = tempTask.description
              .substring(0, tempTask.description.length - 1);
        }
        var res = await updateTask(tempTask);
        if (res) {
          setState(() {
            widget.task.description = tempTask.description;
            widget.task.editMode = false;
            taskListProvider.taskEditMode = false;
          });
        }
      }
    }
  }

  Widget buildListRow(BuildContext context) {
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);

    if (widget.task.editMode) {
      textEditingController =
          TextEditingController(text: widget.task.description);
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
                                taskListProvider.deleteEditorItem();
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
                                taskListProvider.deleteEditorItem();
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
                                      taskListProvider.deleteEditorItem();
                                    } else {
                                      var tempTask = Task.from(widget.task);
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
                                        setState(() {
                                          widget.task.description =
                                              tempTask.description;
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
                  onPressed: taskListProvider.loading
                      ? null
                      : () async {
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
                    taskListProvider.taskEditMode = false;
                    if (widget.task.isNewItem) {
                      taskListProvider.deleteEditorItem();
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
            taskListProvider.deleteItem(widget.task.ID, context);
          }
        },
        child: Card(
          color: getTileColor(taskListProvider.currentTask != null &&
              taskListProvider.currentTask!.ID == widget.task.ID),
          shape: const BeveledRectangleBorder(),
          /* shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),*/
          child: ListTile(
            /*tileColor: taskListProvider.currentTask == null
                      ? null
                      : getTileColor(
                          taskListProvider.currentTask!.ID == widget.task.ID),*/
            onTap: () => onTap(widget.task),
            onLongPress: () => onLongPress(widget.task),
            leading: Checkbox(
                checkColor: widget.task.cancelled ? Colors.grey : null,
                shape: const CircleBorder(),
                fillColor: MaterialStateProperty.all(
                    widget.task.cancelled ? Colors.grey : Colors.green),
                value: widget.task.closed,
                onChanged: (value) => taskClosedOnChanged(value, widget.task)),
            title: taskListProvider.searchMode
                ? HighlightText(
                    highlightColor: Colors.red,
                    text: widget.task.description,
                    words: taskListProvider.searchHighlightedWords,
                    maxLines: 5,
                  )
                : Text(
                    widget.task.description,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    style: widget.task.cancelled
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontStyle: FontStyle.italic)
                        : null,
                  ),
            subtitle: Column(
              children: [
                if (widget.task.lastMessage.isNotEmpty ||
                    widget.task.unreadMessages > 0)
                  taskListProvider.searchMode
                      ? HighlightText(
                          leading: widget.task.lastMessageUserName.isNotEmpty
                              ? TextSpan(
                                  text: "${widget.task.lastMessageUserName}: ",
                                  style: const TextStyle(color: Colors.blue))
                              : null,
                          highlightColor: Colors.red,
                          text: widget.task.lastMessage,
                          words: taskListProvider.searchHighlightedWords,
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
                                NumberInStadium(
                                    number: widget.task.unreadMessages),
                            ]),
                Row(
                  children: [
                    const Spacer(),
                    if (widget.task.completed)
                      const Label(
                        text: "Done",
                        backgroundColor: Colors.green,
                      ),
                    if (widget.task.cancelled)
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
    }
  }

  Future<void> onTap(Task task) async {
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);

    msgListProvider.clear(true);
    msgListProvider.taskID = task.ID;
    msgListProvider.task = task;

    if (isDesktopMode) {
      if (sessionID == "" || !mounted) {
        return;
      }

      final taskListProvider =
          Provider.of<TasksListProvider>(context, listen: false);

      task.read = true;
      task.unreadMessages = 0;
      taskListProvider.currentTask = task;
      msgListProvider.requestMessages();
      taskListProvider.refresh();

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
      openTask(context, task, msgListProvider);
      setState(() {
        task.read = true;
        task.unreadMessages = 0;
      });
    }
  }

  void onLongPress(Task task) {
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);

    setState(() {
      var foundTask = taskListProvider.items
          .firstWhereOrNull((element) => element.ID == task.ID);
      if (foundTask != null) {
        foundTask.editMode = true;
        foundTask.isNewItem = false;
      }
    });
  }

  void taskClosedOnChanged(bool? value, Task task) async {
    if (value == null) return;

    setState(() {
      task.closed = value;
    });

    //var res = await updateTask(Task.from(task)..closed = value);

    //if (res) {
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    final res = await createMessage(
        text: "",
        task: task,
        msgListProvider: msgListProvider,
        messageAction: value
            ? MessageAction.CloseTaskAction
            : MessageAction.ReopenTaskAction);
    //} else {
    /*setState(() {
        task.closed = !value;
      });*/
    //}
    if (!res) {
      setState(() {
        task.closed = !value;
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
    MaterialPageRoute(builder: (context) => TaskMessagesPage(task: task)),
  );
}
