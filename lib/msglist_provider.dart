//import 'dart:ffi';

import 'dart:convert';
//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:http/http.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:todochat/models/task.dart';
import 'package:todochat/state/tasks.dart';

//import 'package:http/http.dart';
//import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'HttpClient.dart' as HTTPClient;

import 'package:http/http.dart' as http;
import 'HttpClient.dart';
import 'customWidgets.dart';
import 'utils.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';
//import 'package:text_selection_controls/text_selection_controls.dart';
import 'todochat.dart';

class UploadingFilesStruct {
  late HTTPClient.MultipartRequest? multipartRequest;
  late Uint8List loadingFileData;
  UploadingFilesStruct({this.multipartRequest, required this.loadingFileData});
}

Map<String, UploadingFilesStruct> uploadingFiles = {};

enum MessageAction {
  CreateUpdateMessageAction,
  CompleteTaskAction,
  ReopenTaskAction,
  CloseTaskAction,
  CancelTaskAction,
  RemoveCompletedLabelAction,
}

class Message {
  int ID = 0;
  int taskID = 0;
  int projectID = 0;
  Task? task;
  DateTime? created_at;
  String text = "";
  String? quotedText = "";
  int parentMessageID = 0;
  int userID = 0;
  String userName = "";
  String fileName = "";
  int fileSize = 0;
  String localFileName = "";
  String parentsmallImageName = "";
  String smallImageName = "";
  bool isImage = false;
  //Uint8List? previewSmallImageData;
  int smallImageWidth = 0;
  int smallImageHeight = 0;
  bool isTaskDescriptionItem = false;
  bool loadingFile = false;
  //Uint8List? loadingFileData;
  bool loadinInProcess = false;
  String tempID = "";
  bool isSelected = false;
  MessageAction messageAction = MessageAction.CreateUpdateMessageAction;
  Message(
      {required this.taskID,
      this.text = "",
      this.quotedText = "",
      this.parentMessageID = 0,
      this.parentsmallImageName = "",
      this.created_at,
      this.ID = 0,
      this.userID = 0,
      this.smallImageName = "",
      this.localFileName = "",
      this.fileName = "",
      this.isImage = false,
      this.isTaskDescriptionItem = false,
      this.loadingFile = false,
      //this.loadingFileData,
      this.tempID = "",
      this.loadinInProcess = false,
      this.messageAction = MessageAction.CreateUpdateMessageAction});

  Map<String, dynamic> toJson() {
    int messageActionInt = 0;
    switch (messageAction) {
      case MessageAction.CreateUpdateMessageAction:
        messageActionInt = 0;
        break;

      case MessageAction.CompleteTaskAction:
        messageActionInt = 1;
        break;

      case MessageAction.ReopenTaskAction:
        messageActionInt = 2;
        break;

      case MessageAction.CloseTaskAction:
        messageActionInt = 3;
        break;

      case MessageAction.CancelTaskAction:
        messageActionInt = 4;
        break;
      case MessageAction.RemoveCompletedLabelAction:
        messageActionInt = 5;
        break;

      default:
    }
    return {
      'ID': ID,
      'taskID': taskID == 0 ? task?.ID : taskID,
      'projectID': projectID,
      'created_at': created_at,
      'text': text,
      'quotedText': quotedText,
      'parentMessageID': parentMessageID,
      'parentsmallImageName': parentsmallImageName,
      'userID': userID,
      'userName': userName,
      'fileName': fileName,
      'fileSize': fileSize,
      'isImage': isImage,
      'smallImageName': smallImageName,
      'localFileName': localFileName,
      'smallImageWidth': smallImageWidth,
      'smallImageHeight': smallImageHeight,
      'isTaskDescriptionItem': isTaskDescriptionItem,
      'TempID': tempID,
      'LoadinInProcess': loadinInProcess,
      'MessageAction': messageActionInt,
    };
  }

  Message.fromJson(Map<String, dynamic> json) {
    ID = json['ID'];
    created_at = DateTime.tryParse(json['Created_at']);
    text = json['Text'];
    quotedText = json['QuotedText'];
    var value = json['ParentMessageID'];
    parentMessageID = value ?? 0;
    parentsmallImageName = json['ParentsmallImageName'] ?? "";
    taskID = json['TaskID'];
    projectID = json['ProjectID'];
    userID = json['UserID'];
    userName = json['UserName'];
    isImage = json['IsImage'];
    fileName = json['FileName'];
    fileSize = json['FileSize'];
    smallImageName = json['SmallImageName'];
    localFileName = json['LocalFileName'];
    smallImageWidth = json['SmallImageWidth'];
    smallImageHeight = json['SmallImageHeight'];
    // var previewSmallImageBase64 = json['PreviewSmallImageBase64'];
    // if (previewSmallImageBase64 != null && previewSmallImageBase64 != "") {
    //   previewSmallImageData = fromBase64(previewSmallImageBase64);
    // }
    value = json['IsTaskDescriptionItem'];
    isTaskDescriptionItem = value ?? false;
    tempID = json["TempID"];
    loadinInProcess = json["LoadinInProcess"];
    int? messageActionIntValue = json["MessageAction"];

    switch (messageActionIntValue) {
      case 0:
        messageAction = MessageAction.CreateUpdateMessageAction;
        break;
      case 1:
        messageAction = MessageAction.CompleteTaskAction;
        break;
      case 2:
        messageAction = MessageAction.ReopenTaskAction;
        break;
      case 3:
        messageAction = MessageAction.CloseTaskAction;
        break;
      case 4:
        messageAction = MessageAction.CancelTaskAction;
        break;

      case 5:
        messageAction = MessageAction.RemoveCompletedLabelAction;
        break;

      default:
        messageAction = MessageAction.CreateUpdateMessageAction;
    }
  }
}

class MsgListProvider extends ChangeNotifier {
  List<Message> items = [];
  num offset = 0;
  int lastID = 0;
  bool loading = false;
  //int taskID = 0;
  Task task = Task();
  int foundMessageID = 0;
  AutoScrollController? scrollController;
  bool isOpen = isDesktopMode;
  String quotedText = "";
  String parentsmallImageName = "";
  int currentParentMessageID = 0;

  void jumpTo(int messageID) {
    if (messageID == 0) return;
    var index = items.indexWhere((element) => element.ID == messageID);
    if (index >= 0 && scrollController != null) {
      try {
        scrollController!
            .scrollToIndex(index, preferPosition: AutoScrollPosition.end);
      } catch (e) {}
    }
  }

  void refresh() {
    notifyListeners();
  }

  void clear([bool refresh = false]) {
    for (var item in items) {
      if (!item.loadinInProcess) {
        uploadingFiles.removeWhere((key, value) => key == item.tempID);
      }
    }

    items.clear();
    offset = 0;
    lastID = 0;
    loading = false;
    quotedText = "";
    parentsmallImageName = "";
    currentParentMessageID = 0;
    if (refresh) {
      this.refresh();
    }
  }

  void addItems(dynamic data) {
    for (var item in data) {
      var message = Message.fromJson(item);
      if (message.taskID == task.ID) {
        /*if (message.tempID.isNotEmpty) {
          final res = uploadingFiles[message.tempID];
          if (res != null && res.loadingFileData.isNotEmpty) {
            message.loadingFileData = res.loadingFileData;
          }
        }*/
        if (items.firstWhereOrNull((element) => element.ID == message.ID) ==
            null) {
          items.add(message);
        }
      }
    }
    loading = false;
    if (data.length > 0) {
      lastID = data[data.length - 1]["ID"];
      notifyListeners();
    }
  }

  void addUploadingItem(Message message, Uint8List loadingFileData) {
    if (message.taskID != task.ID) {
      return;
    }
    message.tempID = UniqueKey().toString();
    message.loadinInProcess = true;
    items.insert(0, message);
    uploadingFiles[message.tempID] =
        UploadingFilesStruct(loadingFileData: loadingFileData);

    createMessageWithFile(
      text: message.text,
      fileData: loadingFileData,
      fileName: message.fileName,
      msgListProvider: this,
      tempID: message.tempID,
    );
    notifyListeners();
  }

  void unselectItems() {
    for (var element in items) {
      if (element.isSelected) {
        element.isSelected = false;
      }
    }
    refresh();
  }

  void selectItem(Message message, [bool multiselect = false]) {
    if (!multiselect) {
      int foundIndex =
          items.indexWhere((element) => element.isSelected == true);
      if (foundIndex >= 0) {
        items[foundIndex].isSelected = false;
      }
    }
    message.isSelected = true;
    refresh();
  }

  bool addItem(Message message) {
    if (message.taskID != task.ID || !isOpen) {
      return false;
    }
    bool created = false;
    if (message.tempID.isNotEmpty) {
      int foundIndex =
          items.indexWhere((element) => element.tempID == message.tempID);
      if (foundIndex >= 0) {
        items[foundIndex] = message;
      } else if (!message.loadinInProcess ||
          uploadingFiles.containsKey(message.tempID)) {
        items.insert(0, message);
        created = true;
        notifyListeners();
      }
    } else {
      final foundItem =
          items.firstWhereOrNull((element) => element.ID == message.ID);
      if (foundItem == null && !message.loadinInProcess) {
        items.insert(0, message);
        created = true;
        notifyListeners();
      }
    }
    return created;
  }

  void deleteItem(int messageID) async {
    items.removeWhere((item) => item.ID == messageID);
    notifyListeners();
  }

  Future<bool> deleteMesage(int messageID) async {
    if (sessionID == "") {
      return false;
    }

    Map<String, String> headers = {"sessionID": sessionID};
    Response response;

    try {
      response = await HTTPClient.httpClient.delete(
          HTTPClient.setUriProperty(serverURI,
              path: 'deleteMessage/$messageID'),
          headers: headers);
    } catch (e) {
      return false;
    }

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }

  Future<bool> requestMessages(
      TasksState taskListProvider, BuildContext context) async {
    if (loading) {
      return false;
    }

    if (ws == null) {
      await Future.delayed(const Duration(seconds: 2));
    }

    loading = true;

    if (sessionID == "") {
      loading = false;
      return false;
    }

    Response response;

    bool doReconnect = false;
    try {
      response = await HTTPClient.httpClient.get(
          HTTPClient.setUriProperty(serverURI, path: "messages"),
          headers: {
            "taskID": task.ID.toString(),
            "lastID": lastID.toString(),
            "limit": "30"
          });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        loading = false;
        addItems(data);
      } else if (response.statusCode == 401) {
        doReconnect = true;
        loading = false;
      }
    } catch (e) {
      doReconnect = true;
      loading = false;
    }

    if (doReconnect) {
      await reconnect(taskListProvider, context, true);
      if (ws != null) {
        ws!.sink.add(jsonEncode({
          "sessionID": sessionID,
          "command": "getMessages",
          "lastID": lastID.toString(),
          "messageIDPosition": task.lastMessageID.toString(),
          "limit": "30",
          "taskID": task.ID.toString(),
        }));
      }
    }
    loading = false;

    return true;
  }

  Future<Uint8List> getFile(String localFileName,
      {required BuildContext context,
      Function(List<int> value)? onData,
      Function? onError,
      void Function()? onDone,
      bool? cancelOnError}) async {
    Uint8List res = Uint8List(0);
    if (sessionID == "") {
      return res;
    }

    http.MultipartRequest request = http.MultipartRequest(
        'GET',
        HTTPClient.setUriProperty(serverURI,
            path: 'getFile',
            queryParameters: {"localFileName": localFileName}));

    request.headers["sessionID"] = sessionID;
    request.headers["content-type"] = "application/json; charset=utf-8";

    var streamedResponse = await request.send();
    if (streamedResponse.statusCode == 200) {
      try {
        if (onData != null || onDone != null || cancelOnError != null) {
          streamedResponse.stream.listen(onData,
              onError: onError, onDone: onDone, cancelOnError: cancelOnError);
        } else {
          Response response = await Response.fromStream(streamedResponse);
          res = response.bodyBytes;
        }
      } catch (e) {
        toast(e.toString(), context);
        return res;
      }
      /*var data = jsonDecode(response.body) as Map<String, dynamic>;
      message.ID = data["ID"];
      message.userID = data["UserID"];*/
      //return true;
    }
    return res;
  }

  Future<bool> createMessage(
      {required String text,
      required Task? task, // task could be different from the current one
      bool isTaskDescriptionItem = false,
      bool isImage = false,
      String fileName = "",
      String tempID = "",
      bool loadinInProcess = false,
      MessageAction messageAction =
          MessageAction.CreateUpdateMessageAction}) async {
    if (task == null) {
      return false;
    }

    Message message = Message(
      taskID: task.ID,
      text: text,
      fileName: path.basename(fileName),
      isImage: isImage,
      isTaskDescriptionItem: isTaskDescriptionItem,
      tempID: tempID,
      loadinInProcess: loadinInProcess,
      messageAction: messageAction,
      quotedText: quotedText,
      parentsmallImageName: parentsmallImageName,
      parentMessageID: currentParentMessageID,
    );

    Response response;
    try {
      response = await HTTPClient.httpClient.post(
          setUriProperty(serverURI, path: 'createMessage'),
          body: jsonEncode(message));
    } catch (e) {
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        toast(e.toString(), context);
      }

      return false;
    }
    //request.headers.contentLength = utf8.encode(body).length;

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body) as Map<String, dynamic>;

      Message message = Message.fromJson(data);
      // final tempID = msgListProvider.taskID;
      //msgListProvider.taskID = task.ID;
      addItem(message);
      //msgListProvider.taskID = tempID;
      quotedText = "";
      parentsmallImageName = "";
      currentParentMessageID = 0;

      return true;
    }

    return false;
  }

  Future<bool> createMessageWithFile(
      {required String text,
      required MsgListProvider msgListProvider,
      Uint8List? fileData,
      String fileName = "",
      bool isTaskDescriptionItem = false,
      required String tempID}) async {
    if (sessionID == "" || fileData == null) {
      return false;
    }

    final foundUploadingFile = uploadingFiles[tempID];
    if (foundUploadingFile == null) {
      return false;
    }

    bool isImage = isImageFile(fileName);

    final res = await createMessage(
        text: text,
        task: msgListProvider.task,
        tempID: tempID,
        fileName: fileName,
        isImage: isImage,
        loadinInProcess: true);
    if (!res) {
      return false;
    }

    final request = HTTPClient.MultipartRequest(
      'POST',
      setUriProperty(serverURI, path: 'createMessageWithFile'),
    );

    foundUploadingFile.multipartRequest = request;

    request.headers["sessionID"] = sessionID;
    request.headers["content-type"] = "application/json; charset=utf-8";

    Message message = Message(
        taskID: msgListProvider.task.ID,
        text: text,
        fileName: path.basename(fileName),
        isImage: isImage,
        isTaskDescriptionItem: isTaskDescriptionItem,
        tempID: tempID);

    request.fields["Message"] = jsonEncode(message);
    request.files.add(
        http.MultipartFile.fromBytes("File", fileData, filename: fileName));

    StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send();
    } catch (e) {
      uploadingFiles.remove(tempID);
      msgListProvider.refresh();
      return false;
    }

    //uploadingFiles.remove(tempID);
    if (streamedResponse.statusCode == 200) {
      msgListProvider.refresh();
      return true;
    }
    uploadingFiles.remove(tempID);
    msgListProvider.refresh();
    return false;
  }
}
