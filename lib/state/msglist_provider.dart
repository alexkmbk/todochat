//import 'dart:ffi';

import 'dart:convert';
//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:http/http.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:todochat/models/message.dart';
import 'package:todochat/models/task.dart';
import 'package:todochat/state/tasks.dart';

//import 'package:http/http.dart';
//import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../HttpClient.dart' as HTTPClient;

import 'package:http/http.dart' as http;
import '../HttpClient.dart';
import '../customWidgets.dart';
import '../utils.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';
//import 'package:text_selection_controls/text_selection_controls.dart';
import '../todochat.dart';

class UploadingFilesStruct {
  late HTTPClient.MultipartRequest? multipartRequest;
  late Uint8List loadingFileData;
  UploadingFilesStruct({this.multipartRequest, required this.loadingFileData});
}

Map<String, UploadingFilesStruct> uploadingFiles = {};

class MsgListProvider extends ChangeNotifier {
  List<Message> items = [];
  num offset = 0;
  int lastID = 0;
  bool loading = false;
  //int taskID = 0;
  Task task = Task();
  int foundMessageID = 0;
  AutoScrollController scrollController = AutoScrollController();
  bool isOpen = isDesktopMode;
  String quotedText = "";
  String parentsmallImageName = "";
  int currentParentMessageID = 0;
  bool editMode = false;
  final messageInputController = TextEditingController();
  final messageTextFieldFocusNode = FocusNode();
  bool setEditBoxFocus = false;
  Message? editingMessage;

  void jumpTo(int messageID) {
    if (messageID == 0) return;
    var index = items.indexWhere((element) => element.ID == messageID);
    if (index >= 0) {
      try {
        scrollController.scrollToIndex(index,
            preferPosition: AutoScrollPosition.end);
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
      tempID: message.tempID,
    );
    notifyListeners();
  }

  void unselectItems() {
    // for (var element in items) {
    //   if (element.isSelected) {
    //     element.isSelected = false;
    //   }
    // }

    // refresh();
  }

  void selectItem(Message message, [bool multiselect = false]) {
    // if (!multiselect) {
    //   int foundIndex =
    //       items.indexWhere((element) => element.isSelected == true);
    //   if (foundIndex >= 0) {
    //     items[foundIndex].isSelected = false;
    //   }
    // }
    // message.isSelected = true;
    // refresh();
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

  bool updateItem(Message message) {
    if (message.taskID != task.ID || !isOpen) {
      return false;
    }
    bool updated = false;

    int foundIndex = items.indexWhere((element) => element.ID == message.ID);
    if (foundIndex >= 0 && items[foundIndex] != message) {
      items[foundIndex] = message;
      updated = true;
      notifyListeners();
    }
    return updated;
  }

  void deleteItem(int messageID, [Task? updatedTask]) async {
    items.removeWhere((item) => item.ID == messageID);
    if (updatedTask != null) {
      task = updatedTask;
    }
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
        'POST',
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

// Get message by ID from server
  Future<Message?> getMessageByID(int messageID) async {
    if (sessionID == "") {
      return null;
    }

    Response response;
    try {
      response = await HTTPClient.httpClient.get(
          HTTPClient.setUriProperty(serverURI, path: 'message/$messageID'),
          headers: {"sessionID": sessionID});
    } catch (e) {
      return null;
    }

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      Message message = Message.fromJson(data);
      if (message.taskID == task.ID) {
        return message;
      }
    }
    return null;
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

  Future<bool> updateMessage({
    required String text,
  }) async {
    if (editingMessage == null) return false;

    editingMessage!.text = text;
    Response response;
    try {
      response = await HTTPClient.httpClient.post(
          setUriProperty(serverURI, path: 'updateMessage'),
          body: jsonEncode(editingMessage));
    } catch (e) {
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        toast(e.toString(), context);
      }

      return false;
    }
    if (response.statusCode == 200) {
      editMode = false;
      quotedText = "";
      parentsmallImageName = "";
      currentParentMessageID = 0;
      updateItem(editingMessage!);
      return true;
    }

    return false;
  }

  Future<bool> createMessageWithFile(
      {required String text,
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
        task: task,
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
        taskID: task.ID,
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
      refresh();
      return false;
    }

    //uploadingFiles.remove(tempID);
    if (streamedResponse.statusCode == 200) {
      refresh();
      return true;
    }
    uploadingFiles.remove(tempID);
    refresh();
    return false;
  }
}
