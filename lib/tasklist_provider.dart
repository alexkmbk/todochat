import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:todochat/tasklist.dart';
import 'package:todochat/utils.dart';
import 'HttpClient.dart';
import 'LoginPage.dart';
import 'ProjectsList.dart';
import 'package:collection/collection.dart';
import 'todochat.dart';
import 'msglist_provider.dart';

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
      this.editMode = false});

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
    creation_date = formJsonToDate(json['Creation_date']);
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

class TaskListProvider extends ChangeNotifier {
  Project? project;
  int? projectID;
  List<Task> items = [];
  int lastID = 0;
  String? lastCreation_date;
  bool loading = false;
  bool uploading = false;
  bool searchMode = false;
  bool taskEditMode = false;
  bool isNewItem = false;
  bool showClosed = true;
  List<String> searchHighlightedWords = [];
  String search = "";
  Task? currentTask;

  TextEditingController textEditingController = TextEditingController(text: "");

  void refresh() {
    notifyListeners();
  }

  void setCurrentTask(Task? currentTask, BuildContext context) {
    if (this.currentTask != currentTask) {
      this.currentTask = currentTask;

      final msgListProvider =
          Provider.of<MsgListProvider>(context, listen: false);
      msgListProvider.clear();
      msgListProvider.taskID = currentTask == null ? 0 : currentTask.ID;
      msgListProvider.task = currentTask;
      msgListProvider.requestMessages(this, context);
      msgListProvider.refresh();
    }
  }

  void clear() {
    items.clear();
    lastID = 0;
    lastCreation_date = null;
    taskEditMode = false;
  }

  void setProjectID(int? value) {
    if (projectID != value) {
      projectID = value;
      notifyListeners();
    }
  }

  void addEditorItem() {
    taskEditMode = true;
    isNewItem = true;
    items.insert(0, Task(editMode: true));
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

      if (index < items.length) {
        setCurrentTask(items[index], context);
      } else {
        setCurrentTask(null, context);
      }
      refresh();
    }
  }

  Future<bool> deleteTask(int taskID, BuildContext context) async {
    if (sessionID == "") {
      return false;
    }

    Response response;

    try {
      response = await httpClient
          .delete(setUriProperty(serverURI, path: 'todo/$taskID'));

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      reconnect(this, context, true);
    }

    return false;
  }

  Future<Task?> createTask(String description, MsgListProvider msgListProvider,
      BuildContext context) async {
    if (sessionID == "") {
      return null;
    }

    Task task = Task(description: description);
    Response response;
    try {
      response = await httpClient.post(setUriProperty(serverURI, path: 'todo'),
          body: jsonEncode(task), headers: {"ProjectID": projectID.toString()});
    } catch (e) {
      toast(e.toString(), context);
      reconnect(this, context, true);
      return null;
    }

    //request.headers.contentLength = utf8.encode(body).length;

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      task.projectID = data["ProjectID"];
      task.ID = data["ID"];
      task.creation_date =
          DateTime.tryParse(data["Creation_date"]) ?? DateTime.utc(0);
      task.authorID = data["AuthorID"];
      task.authorName = data["AuthorName"];
      task.read = true;
      currentTask = task;
      addItem(task);
      msgListProvider.task = task;
      msgListProvider.taskID = task.ID;
      msgListProvider.createMessage(
          text: "", task: task, isTaskDescriptionItem: true);

      return task;
    }

    return null;
  }

  Future<bool> onAddTask(String description, BuildContext context) async {
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);

    Task? task = await createTask(description, msgListProvider, context);

    loading = false;

    if (task == null) return false;

    if (isDesktopMode) {
      msgListProvider.clear(true);
    } else {
      msgListProvider.clear(false);
      openTask(context, task, msgListProvider);
    }

    return true;
  }

  void saveEditingItem(BuildContext context) async {
    if (loading) {
      return;
    }

    var editingTask =
        items.firstWhereOrNull((element) => element.editMode == true);

    if (editingTask == null) {
      return;
    }

    var text = textEditingController.text.trim();

    if (text.isNotEmpty) {
      if (isNewItem) {
        final res = await onAddTask(text, context);
        if (res) {
          deleteEditorItem();
        }
      } else {
        var tempTask = Task.from(editingTask);
        tempTask.description = text;
        if (tempTask.description.endsWith('\n')) {
          tempTask.description = tempTask.description
              .substring(0, tempTask.description.length - 1);
        }
        var res = await updateTask(tempTask);
        if (res) {
          editingTask.description = tempTask.description;
          editingTask.editMode = false;
          taskEditMode = false;
        }
      }
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

    if (sessionID == "" || loading || !context.mounted || searchMode) {
      return;
    }

    loading = true;

    var url = setUriProperty(serverURI, path: 'tasks', queryParameters: {
      "ProjectID": projectID.toString(),
      "lastID": lastID.toString(),
      "lastCreation_date": lastCreation_date == null
          ? null
          : formDateToJsonUtc(formJsonToDate(lastCreation_date)),
      "limit": "25",
      "showClosed": showClosed.toString(),
    });

    Response response;
    try {
      //response = await httpClient.get(url, headers: {"sessionID": sessionID});
      response = await httpClient.get(url);
    } catch (e) {
      loading = false;
      return;
    }

    if (response.statusCode == 200 && response.body != "") {
      var data = jsonDecode(response.body);

      var tasks = data["tasks"];

      if (tasks == null) return;

      final msgListProvider =
          Provider.of<MsgListProvider>(context, listen: false);

      if (tasks.length > 0) {
        var lastItem = tasks[tasks.length - 1];
        lastID = lastItem["ID"];
        lastCreation_date = lastItem["Creation_date"];

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
            final taskListProvider =
                Provider.of<TaskListProvider>(context, listen: false);

            msgListProvider.requestMessages(taskListProvider, context);
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
