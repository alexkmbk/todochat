//import 'dart:ffi';

import 'dart:convert';
//import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

import 'package:provider/provider.dart';
//import 'package:http/http.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'HttpClient.dart' as HTTPClient;

import 'package:http/http.dart' as http;
import 'HttpClient.dart';
import 'customWidgets.dart';
import 'inifiniteTaskList.dart';
import 'utils.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';
//import 'package:text_selection_controls/text_selection_controls.dart';
import 'text_selection_controls.dart';
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

class MsgListProvider extends ChangeNotifier {
  List<Message> items = [];
  num offset = 0;
  int lastID = 0;
  bool loading = false;
  int taskID = 0;
  Task? task;
  int foundMessageID = 0;
  ItemScrollController? scrollController;
  bool isOpen = isDesktopMode;
  String quotedText = "";
  String parentsmallImageName = "";
  int currentParentMessageID = 0;

  void jumpTo(int messageID) {
    if (messageID == 0) return;
    var index = items.indexWhere((element) => element.ID == messageID);
    if (index >= 0 && scrollController != null) {
      try {
        scrollController!.jumpTo(index: index);
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
    //taskID = 0;
    loading = false;
    quotedText = "";
    parentsmallImageName = "";
    currentParentMessageID = 0;
    if (refresh) {
      this.refresh();
    }
  }

  void addItems(dynamic data) {
    bool notify = false;
    for (var item in data) {
      var message = Message.fromJson(item);
      if (message.taskID == taskID) {
        /*if (message.tempID.isNotEmpty) {
          final res = uploadingFiles[message.tempID];
          if (res != null && res.loadingFileData.isNotEmpty) {
            message.loadingFileData = res.loadingFileData;
          }
        }*/
        if (items.firstWhereOrNull((element) => element.ID == message.ID) ==
            null) {
          items.add(message);
          notify = true;
        }
      }
    }
    loading = false;
    if (data.length > 0) {
      lastID = data[data.length - 1]["ID"];
    }
    //if (notify) {
    notifyListeners();
    // }
  }

  void addUploadingItem(Message message, Uint8List loadingFileData) {
    if (message.taskID != taskID) {
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
    if (message.taskID != taskID || !isOpen) {
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
      TasksListProvider taskListProvider, BuildContext context) async {
    if (sessionID == "") {
      return false;
    }

    if (ws == null) {
      await Future.delayed(const Duration(seconds: 2));
    }

    loading = true;

    if (sessionID == "") {
      return false;
    }

    Map<String, String> headers = {
      "sessionID": sessionID,
      "taskID": taskID.toString(),
      "lastID": lastID.toString(),
      "limit": "30"
    };
    Response response;

    bool doReconnect = false;
    try {
      response = await HTTPClient.httpClient.get(
          HTTPClient.setUriProperty(serverURI, path: "messages"),
          headers: headers);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        loading = false;
        addItems(data);
      } else if (response.statusCode == 401) {
        doReconnect = true;
      }
    } catch (e) {
      doReconnect = true;
    }

    if (doReconnect) {
      await reconnect(taskListProvider, context, true);
      if (ws != null) {
        ws!.sink.add(jsonEncode({
          "sessionID": sessionID,
          "command": "getMessages",
          "lastID": lastID.toString(),
          "messageIDPosition": task?.lastMessageID.toString() ?? "0",
          "limit": "30",
          "taskID": taskID.toString(),
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
  Uint8List? previewSmallImageData;
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
      'previewSmallImageBase64': toBase64(previewSmallImageData),
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
    var previewSmallImageBase64 = json['PreviewSmallImageBase64'];
    if (previewSmallImageBase64 != null && previewSmallImageBase64 != "") {
      previewSmallImageData = fromBase64(previewSmallImageBase64);
    }
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

typedef OnDeleteFn = Future<bool> Function(int messageID);

class InifiniteMsgList extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final ItemScrollController scrollController;

  //final Future<bool> Function(int messageID) onDelete;
  /*final Future<Uint8List> Function(String localFileName,
      {Function(List<int> value)? onData,
      Function? onError,
      void Function()? onDone,
      bool? cancelOnError}) getFile;*/

  //final ItemBuilder itemBuilder;
  //final Task task;
  const InifiniteMsgList({
    Key? key,
    required this.scrollController,
    required this.itemPositionsListener,
  }) : super(key: key);

  @override
  InifiniteMsgListState createState() {
    return InifiniteMsgListState();
  }
}

class InifiniteMsgListState extends State<InifiniteMsgList> {
  //late MsgListProvider _msgListProvider;

  final _messageInputController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ItemScrollController itemsScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final messageTextFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);

    if (msgListProvider.task == null || msgListProvider.task?.ID == 0) {
      return const Center(child: Text("No any task was selected"));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (msgListProvider.foundMessageID > 0 &&
            msgListProvider.items.length > 1) {
          msgListProvider.jumpTo(msgListProvider.foundMessageID);
          msgListProvider.foundMessageID = 0;
        }
      });

      if (msgListProvider.loading) {
        return const Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(),
            ));
      }
      return Column(children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: () => msgListProvider.unselectItems(),
            child: ScrollablePositionedList.builder(
                reverse: true,
                itemScrollController: widget.scrollController,
                itemPositionsListener: widget.itemPositionsListener,
                itemCount: msgListProvider.items.length,
                extraScrollSpeed:
                    Platform().isAndroid || Platform().isIOS ? 0 : 40,
                itemBuilder: (context, index) {
                  if (msgListProvider.items.isEmpty) {
                    return const Text("");
                  }
                  var item = msgListProvider.items[index];
                  /*if (item.tempID.isNotEmpty && item.loadinInProcess) {
              return LoadingFileBubble(
                index: index,
                isCurrentUser: item.userID == currentUserID,
                message: item,
                msgListProvider: msgListProvider,
                getFile: widget.getFile,
              );
            } else {*/
                  return ChatBubble(
                    index: index,
                    isCurrentUser: item.userID == currentUserID,
                    message: item,
                    msgListProvider: msgListProvider,
                    messageTextFieldFocusNode: messageTextFieldFocusNode,
                    onDismissed: (direction) async {
                      if (await msgListProvider.deleteMesage(item.ID)) {
                        msgListProvider.deleteItem(item.ID);
                      }
                    },
                  );
                }
                /*} else if (index == items.length && end) {
            return const Center(child: Text('End of list'));*/
                //}
                /*else {
            _getMoreItems();
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }*/
                //return const Center(child: Text('End of list'));
                // },
                ),
          ),
        ),
        // Edit message box
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
              /*border: Border(
                
                top: BorderSide(color: Colors.grey),
                bottom: BorderSide(color: Colors.grey),
              ),*/
            ),
            child: Column(children: [
              if (msgListProvider.quotedText.isNotEmpty ||
                  msgListProvider.parentsmallImageName.isNotEmpty)
                Row(children: [
                  if (msgListProvider.parentsmallImageName.isNotEmpty)
                    networkImage(
                        serverURI.scheme +
                            '://' +
                            serverURI.authority +
                            "/FileStorage/" +
                            msgListProvider.parentsmallImageName,
                        height: Platform().isAndroid ? 30 : 60),
                  Expanded(
                      child: Text(
                    msgListProvider.quotedText,
                    style: const TextStyle(color: Colors.grey),
                  )),
                  SizedBox(
                      width: 20,
                      child: IconButton(
                          onPressed: () {
                            msgListProvider.quotedText = "";
                            msgListProvider.parentsmallImageName = "";
                            msgListProvider.refresh();
                          },
                          icon: const Icon(Icons.close)))
                ]),
              if (msgListProvider.quotedText.isNotEmpty) const Divider(),
              Row(
                children: [
                  if (msgListProvider.task != null)
                    NewMessageActionsMenu(
                      msgListProvider: msgListProvider,
                    ),
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter,
                            control: false): () {
                          if (_messageInputController.text.isNotEmpty) {
                            createMessage(
                              text: _messageInputController.text,
                              task: msgListProvider.task,
                              msgListProvider: msgListProvider,
                            );
                            _messageInputController.text = "";
                          }
                        },
                        const SingleActivator(LogicalKeyboardKey.escape,
                            control: false): () {
                          if (msgListProvider.quotedText.isNotEmpty ||
                              msgListProvider.parentsmallImageName.isNotEmpty) {
                            msgListProvider.quotedText = "";
                            msgListProvider.parentsmallImageName = "";
                            msgListProvider.refresh();
                          }
                        },
                        const SingleActivator(LogicalKeyboardKey.keyV,
                            control: true): () async {
                          ClipboardData? data =
                              await Clipboard.getData('text/plain');

                          if (data != null &&
                              data.text != null &&
                              data.text!.trim().isNotEmpty) {
                            String text = data.text ?? "";
                            _messageInputController.text = text.trim();
                            _messageInputController.selection =
                                TextSelection.fromPosition(TextPosition(
                                    offset:
                                        _messageInputController.text.length));
                          } else {
                            final bytes = await Pasteboard.image;
                            if (bytes != null) {
                              msgListProvider.addUploadingItem(
                                  Message(
                                      taskID: msgListProvider.taskID,
                                      userID: currentUserID,
                                      fileName: "clipboard_image.png",
                                      loadingFile: true,
                                      isImage: true),
                                  bytes);
                            } else {
                              final files = await Pasteboard.files();
                              if (files.isNotEmpty) {
                                for (final file in files) {
                                  var fileData = await readFile(file);
                                  if (fileData.isNotEmpty) {
                                    msgListProvider.addUploadingItem(
                                        Message(
                                            taskID: msgListProvider.taskID,
                                            userID: currentUserID,
                                            fileName: path.basename(file),
                                            loadingFile: true,
                                            isImage: isImageFile(file)),
                                        fileData);
                                  }
                                }
                              } else {
                                var html = await Pasteboard.html;
                                if (html != null && html.isNotEmpty) {
                                  String imageURL = getImageURLFromHTML(html);
                                  if (imageURL.isNotEmpty) {
                                    Response response;
                                    try {
                                      response = await get(Uri.parse(imageURL));
                                    } catch (e) {
                                      toast(e.toString(), context);
                                      return;
                                    }

                                    if (response.statusCode == 200) {
                                      msgListProvider.addUploadingItem(
                                          Message(
                                              taskID: msgListProvider.taskID,
                                              userID: currentUserID,
                                              fileName: "clipboard_image.png",
                                              loadingFile: true,
                                              isImage: true),
                                          response.bodyBytes);
                                    }
                                  } else {
                                    _messageInputController.text = html.trim();
                                    _messageInputController.selection =
                                        TextSelection.fromPosition(TextPosition(
                                            offset: _messageInputController
                                                .text.length));
                                  }
                                }
                              }
                            }
                          }
                        },
                      },
                      child: TextField(
                        focusNode: messageTextFieldFocusNode,
                        autofocus: true,
                        controller: _messageInputController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: const InputDecoration(
                          border: InputBorder.none, // OutlineInputBorder(),
                          hintText: 'Message',
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_messageInputController.text.isNotEmpty) {
                        createMessage(
                            text: _messageInputController.text,
                            task: msgListProvider.task,
                            msgListProvider: msgListProvider);
                        _messageInputController.text = "";
                      }
                    },
                    tooltip: 'New message',
                    icon: const Icon(
                      Icons.send,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();

                      if (result == null) {
                        return;
                      }

                      if (!isWeb() && result.files.single.path != null) {
                        var fileName = result.files.single.path?.trim() ?? "";

                        if (fileName.isNotEmpty) {
                          var res = await readFile(fileName);
                          msgListProvider.addUploadingItem(
                              Message(
                                  taskID: msgListProvider.taskID,
                                  userID: currentUserID,
                                  fileName: path.basename(fileName),
                                  loadingFile: true,
                                  isImage: isImageFile(fileName)),
                              res);
                          _messageInputController.text = "";
                        }
                      } else if (result.files.single.bytes != null &&
                          result.files.single.bytes!.isNotEmpty) {
                        var fileName = result.files.single.name;
                        msgListProvider.addUploadingItem(
                            Message(
                                taskID: msgListProvider.taskID,
                                userID: currentUserID,
                                fileName: path.basename(fileName),
                                loadingFile: true,
                                isImage: isImageFile(fileName)),
                            result.files.single.bytes!);
                        _messageInputController.text = "";
                      }
                    },
                    tooltip: 'Add file',
                    icon: const Icon(Icons.attach_file),
                  )
                ],
              ),
            ]),
          ),
        ),
      ]);
    }
  }
}

class ChatBubble extends StatelessWidget {
  ChatBubble(
      {Key? key,
      required this.message,
      required this.onDismissed,
      required this.isCurrentUser,
      required this.msgListProvider,
      required this.index,
      required this.messageTextFieldFocusNode})
      : super(key: key);
  final Message message;
  final bool isCurrentUser;
  final MsgListProvider msgListProvider;
  final int index;
  final FocusNode messageTextFieldFocusNode;

  double progress = 1.0;
  /*final String text;
  final String isImage = false;
  final Uint8List? smallImageData;
  final bool isCurrentUser;*/
  final DismissDirectionCallback onDismissed;
  /*final Future<Uint8List> Function(String localFileName,
      {Function(List<int> value)? onData,
      Function? onError,
      void Function()? onDone,
      bool? cancelOnError}) getFile;*/

  TextBox? calcLastLineEnd(String text, TextSpan textSpan, BuildContext context,
      BoxConstraints constraints) {
    final richTextWidget = Text.rich(textSpan).build(context) as RichText;
    final renderObject = richTextWidget.createRenderObject(context);
    renderObject.layout(constraints);
    var boxes = renderObject.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length));

/*final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);
*/

    if (boxes.isEmpty) {
      return null;
    } else {
      return boxes.last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final foundStruct = uploadingFiles[message.tempID];
    /*if (foundStruct != null && foundStruct.multipartRequest == null) {
      createMessageWithFile(
        text: message.text,
        fileData: foundStruct.loadingFileData,
        fileName: message.fileName,
        msgListProvider: msgListProvider,
        tempID: message.tempID,
      );
    }*/
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        // asymmetric padding
        padding: message.isTaskDescriptionItem
            ? const EdgeInsets.fromLTRB(0, 0, 0, 0)
            : EdgeInsets.fromLTRB(
                isCurrentUser ? 64.0 : 16.0,
                4,
                isCurrentUser ? 16.0 : 64.0,
                4,
              ),
        child: Align(
            // align the child within the container
            alignment: message.isTaskDescriptionItem ||
                    message.messageAction !=
                        MessageAction.CreateUpdateMessageAction
                ? Alignment.center
                : isCurrentUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
            child:
                drawBubble(context, constraints, foundStruct?.loadingFileData)),
      );
      //}
    });
  }

  Widget getMessageActionDescription(Message message) {
    switch (message.messageAction) {
      case MessageAction.ReopenTaskAction:
        return Text.rich(TextSpan(text: "The task was ", children: <InlineSpan>[
          const WidgetSpan(
            //baseline: TextBaseline.ideographic,
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
              child: Label(text: "Done", backgroundColor: Colors.green)),
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

  Color getBubbleColor() {
    if (message.isTaskDescriptionItem) {
      return msgListProvider.task!.completed
          ? closedTaskColor
          : uncompletedTaskColor;
    } else {
      return isCurrentUser
          ? const Color.fromARGB(255, 187, 239, 251)
          : const Color.fromARGB(255, 224, 224, 224);
    }
  }

  Widget drawBubble(BuildContext context, BoxConstraints constraints,
      Uint8List? loadingFileData) {
    if (message.messageAction != MessageAction.CreateUpdateMessageAction) {
      return DecoratedBox(
        // chat bubble decoration
        decoration: BoxDecoration(
          border: message.isSelected
              ? Border.all(color: Colors.blueAccent, width: 3)
              : Border.all(color: const Color.fromARGB(255, 228, 232, 233)),
          color: const Color.fromARGB(255, 228, 232, 233),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: getMessageActionDescription(message)),
      );
      // Text bubble
    } else if (message.fileName.isEmpty) {
      final text = message.isTaskDescriptionItem
          ? msgListProvider.task?.description
          : message.text;
      final textSpan = TextSpan(text: text);
      BoolRef isQuoteSelected = BoolRef();
      TextSelection textWidgetSelection =
          const TextSelection(baseOffset: 0, extentOffset: 0);
      final textWidget = SelectableText.rich(textSpan,
          selectionControls: messageSelectionControl(msgListProvider, text,
              message.ID, messageTextFieldFocusNode, context),
          onSelectionChanged:
              (TextSelection selection, SelectionChangedCause? cause) {
        textWidgetSelection = selection;
        isQuoteSelected.value =
            textWidgetSelection.start != textWidgetSelection.end;
      });
      /*final TextBox? lastBox =
          calcLastLineEnd(message.text, textSpan, context, constraints);
      bool fitsLastLine = false;
      if (lastBox != null) {
        fitsLastLine =
            constraints.maxWidth - lastBox.right > Timestamp.size.width + 10.0;
      }*/

      return GestureDetectorWithMenu(
        onSecondaryTapDown: (details) {
          msgListProvider.selectItem(message);
        },
        onCopy: () {
          message.isSelected = false;
          var text = message.isTaskDescriptionItem
              ? msgListProvider.task?.description ?? ""
              : message.text;
          if (textWidgetSelection.start != textWidgetSelection.end) {
            text = text.substring(
                textWidgetSelection.start, textWidgetSelection.end);
          }
          //Pasteboard.writeText(text);
          Clipboard.setData(ClipboardData(text: text)).then((value) {
            //toast("Text copied to clipboard", context, 500);
          });
        },
        onReply: () async {
          message.isSelected = false;
          msgListProvider.quotedText = message.isTaskDescriptionItem
              ? msgListProvider.task?.description ?? ""
              : message.text;
          msgListProvider.currentParentMessageID = message.ID;

          msgListProvider.refresh();
          //FocusScope.of(context).unfocus();
          searchFocusNode.unfocus();
          //messageTextFieldFocusNode.dispose();
          messageTextFieldFocusNode.requestFocus();
          msgListProvider.refresh();
        },
        onDelete: () => msgListProvider.deleteMesage(message.ID),
        isQuoteSelected: isQuoteSelected,
        onQuoteSelection: () async {
          message.isSelected = false;
          var text = message.isTaskDescriptionItem
              ? msgListProvider.task?.description ?? ""
              : message.text;
          text = text.substring(
              textWidgetSelection.start, textWidgetSelection.end);
          msgListProvider.quotedText = text;
          msgListProvider.currentParentMessageID = message.ID;
          //FocusScope.of(context).unfocus();
          searchFocusNode.unfocus();
          //messageTextFieldFocusNode.dispose();
          messageTextFieldFocusNode.requestFocus();
          msgListProvider.refresh();
        },
        /*return GestureDetector(
        onSecondaryTapDown: (details) async {
          msgListProvider.selectItem(message);
          final x = details.globalPosition.dx;
          final y = details.globalPosition.dy;
          final selected = await showMenu(
            context: context,
            position: RelativeRect.fromLTRB(x, y, x, y),
            items: [
              PopupMenuItem<String>(
                  child: const Text('Copy'),
                  onTap: () async {
                    message.isSelected = false;
                    var text = message.isTaskDescriptionItem
                        ? msgListProvider.task?.description ?? ""
                        : message.text;
                    if (textWidgetSelection.start != textWidgetSelection.end) {
                      text = text.substring(
                          textWidgetSelection.start, textWidgetSelection.end);
                    }
                    //Pasteboard.writeText(text);
                    Clipboard.setData(ClipboardData(text: text)).then((value) {
                      //toast("Text copied to clipboard", context, 500);
                    });
                  }),
              if (textWidgetSelection.start != textWidgetSelection.end)
                PopupMenuItem<String>(
                    child: const Text('Quote selection'),
                    onTap: () async {
                      message.isSelected = false;
                      var text = message.isTaskDescriptionItem
                          ? msgListProvider.task?.description ?? ""
                          : message.text;
                      text = text.substring(
                          textWidgetSelection.start, textWidgetSelection.end);
                      msgListProvider.quotedText = text;
                      msgListProvider.currentParentMessageID = message.ID;
                      //FocusScope.of(context).unfocus();
                      searchFocusNode.unfocus();
                      //messageTextFieldFocusNode.dispose();
                      messageTextFieldFocusNode.requestFocus();
                      msgListProvider.refresh();
                    }),
              PopupMenuItem<String>(
                  child: const Text('Reply'),
                  onTap: () async {
                    message.isSelected = false;
                    msgListProvider.quotedText = message.isTaskDescriptionItem
                        ? msgListProvider.task?.description ?? ""
                        : message.text;
                    msgListProvider.currentParentMessageID = message.ID;

                    msgListProvider.refresh();
                    //FocusScope.of(context).unfocus();
                    searchFocusNode.unfocus();
                    //messageTextFieldFocusNode.dispose();
                    messageTextFieldFocusNode.requestFocus();
                    msgListProvider.refresh();
                  }),
              if (!message.isTaskDescriptionItem)
                const PopupMenuItem<String>(
                  value: 'Delete',
                  child: Text('Delete'),
                ),
            ],
          );
          if (selected == "Delete") {
            message.isSelected = false;
            var res = await confirmDismissDlg(context);
            if (res ?? false) {
              msgListProvider.deleteMesage(message.ID);
            }
          }
        },*/
        child: DecoratedBox(
          // chat bubble decoration
          decoration: BoxDecoration(
            border: message.isSelected
                ? Border.all(color: Colors.blueAccent, width: 3)
                : Border.all(color: const Color.fromARGB(255, 228, 232, 233)),
            color: getBubbleColor(),
            borderRadius:
                BorderRadius.circular(message.isTaskDescriptionItem ? 0 : 8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            //child: IntrinsicWidth(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (message.quotedText != null && message.quotedText!.isNotEmpty)
                MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () {
                          msgListProvider.jumpTo(message.parentMessageID);
                        },
                        child: Text(
                          message.quotedText ?? "",
                          style: const TextStyle(color: Colors.grey),
                        ))),
              if (message.parentsmallImageName.isNotEmpty)
                MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: networkImage(
                      serverURI.scheme +
                          '://' +
                          serverURI.authority +
                          "/FileStorage/" +
                          message.parentsmallImageName,
                      height: 60,
                      headers: {"sessionID": sessionID},
                      onTap: () {
                        msgListProvider.jumpTo(message.parentMessageID);
                      },
                    )),
              if (message.quotedText != null && message.quotedText!.isNotEmpty)
                const Divider(),
              if (!message.isTaskDescriptionItem &&
                  message.userName.isNotEmpty &&
                  (index == msgListProvider.items.length - 1 ||
                      msgListProvider.items[index + 1].userID !=
                          message.userID))
                Text(
                  message.userName,
                  style: const TextStyle(color: Colors.blue),
                ),
              //Stack(children: [
              if (message.isTaskDescriptionItem)
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Created by ${msgListProvider.task!.authorName} at ${dateFormat(msgListProvider.task!.creation_date)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      SelectableText(
                        msgListProvider.task!.ID.toString().padLeft(6, '0'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ]),
              if (message.isTaskDescriptionItem) const SizedBox(height: 5),
              /*if (lastBox != null)
                      SizedBox.fromSize(
                          size: Size(
                            Timestamp.size.width + lastBox.right,
                            (fitsLastLine ? lastBox.top : lastBox.bottom) +
                                Timestamp.size.height +
                                5,
                          ),
                          child: Container()),*/
              textWidget,
              /*Positioned(
                      left: lastBox != null ? lastBox.right + 5 : 0,
                      //constraints.maxWidth - (Timestamp.size.width + 10.0),
                      top: lastBox != null
                          ? (fitsLastLine ? lastBox.top : lastBox.bottom) + 5
                          : 0.0,
                      child: Timestamp(message.created_at ?? DateTime.now()),
                    ),*/
              /*Align(
                      alignment: Alignment.bottomRight,
                      child: Timestamp(message.created_at ?? DateTime.now()),
                    )*/
            ]),
          ),
          //  ),
        ),
      );
      //);
    } else {
      // Image bubble
      if (message.isImage &&
          (message.smallImageName.isNotEmpty || loadingFileData != null)) {
        return loadingFileData != null
            ? Stack(children: [
                memoryImage(
                  loadingFileData,
                  height: 200,
                  onTap: () => onTapOnFileMessage(message, context),
                ),
                if (message.loadinInProcess)
                  const Positioned(
                      width: 15,
                      height: 15,
                      right: 10,
                      bottom: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        //value: progress,
                      ))
              ])
            : NetworkImageWithMenu(
                serverURI.scheme +
                    '://' +
                    serverURI.authority +
                    "/FileStorage/" +
                    message.smallImageName,
                headers: {"sessionID": sessionID},
                onTap: () {
                  onTapOnFileMessage(message, context);
                },
                onCopy: () async {
                  final fileData = await msgListProvider
                      .getFile(message.smallImageName, context: context);
                  Pasteboard.writeImage(fileData);
                },
                onCopyOriginal: () {
                  final ProgressDialog pd = ProgressDialog(context: context);
                  //pr.show();
                  pd.show(max: 100, msg: 'File Downloading...');
                  List<int> fileData = []; // = Uint8List(0);
                  msgListProvider.getFile(message.localFileName,
                      context: context, onData: (value) {
                    fileData.addAll(value);
                  }, onDone: () async {
                    pd.close();
                    Pasteboard.writeImage(Uint8List.fromList(fileData));
                  });
                },
                onDelete: () => msgListProvider.deleteMesage(message.ID),
                onReply: () {
                  msgListProvider.parentsmallImageName = message.smallImageName;
                  msgListProvider.quotedText = message.text;
                  msgListProvider.currentParentMessageID = message.ID;
                  //messageTextFieldFocusNode.dispose();

                  searchFocusNode.unfocus();
                  messageTextFieldFocusNode.requestFocus();
                  msgListProvider.refresh();
                },
                width: message.smallImageWidth.toDouble(),
                height: message.smallImageHeight.toDouble(),
                previewImageData: message.previewSmallImageData);
      } else {
        // File bubble
        return GestureDetectorWithMenu(
            onTap: () => onTapOnFileMessage(message, context),
            onSecondaryTapDown: (details) {
              msgListProvider.selectItem(message);
            },
            onDelete: () => msgListProvider.deleteMesage(message.ID),
            addMenuItems: [
              if (Platform().isWindows)
                PopupMenuItem<String>(
                    child: const Text('Save as...'),
                    onTap: () async {
                      String? fileName = await FilePicker.platform
                          .saveFile(fileName: message.fileName);

                      if (fileName == null || fileName.isEmpty) {
                        return;
                      }

                      final ProgressDialog pd =
                          ProgressDialog(context: context);
                      //pr.show();
                      pd.show(max: 100, msg: 'File Downloading...');
                      List<int> fileData = []; // = Uint8List(0);
                      msgListProvider.getFile(message.localFileName,
                          context: context, onData: (value) {
                        fileData.addAll(value);
                      }, onDone: () async {
                        pd.close();
                        if (fileData.isNotEmpty) {
                          saveFile(fileData, fileName);
                        }
                      });
                    }),
            ],
            child: DecoratedBox(
              // attached file
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Colors.blue
                    : const Color.fromARGB(255, 224, 224, 224),
                borderRadius: BorderRadius.circular(8),
                border: message.isSelected
                    ? Border.all(color: Colors.blueAccent, width: 3)
                    : Border.all(
                        color: const Color.fromARGB(255, 228, 232, 233)),
              ),
              //child: GestureDetector(
              //onTap: () => onTapOnFileMessage(message, context),
              child: MouseRegion(
                  cursor: SystemMouseCursors.click,
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
                                  message.fileName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                          color: isCurrentUser
                                              ? Colors.white
                                              : Colors.black87),
                                )),
                            if (message.loadinInProcess)
                              const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                        //value: progress,
                                      )))
                          ]))),
              //),
            ));
      }
    }
  }

  void onTapOnFileMessage(Message message, context) async {
    msgListProvider.selectItem(message);
    if (message.isImage && message.localFileName.isNotEmpty) {
      // var res = await getFile(message.localFileName);
      var res = NetworkImage(
          "${serverURI.scheme}://${serverURI.authority}/FileStorage/${message.localFileName}",
          headers: {"sessionID": sessionID});
      //if (res.isNotEmpty) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ImageDialog(imageProvider: res, fileSize: message.fileSize)));
      //}
    } else if (message.isImage && uploadingFiles.containsKey(message.tempID)) {
      // var res = await getFile(message.localFileName);
      var res = Image.memory(uploadingFiles[message.tempID]!.loadingFileData);
      //if (res.isNotEmpty) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ImageDialog(
                  imageProvider: res.image, fileSize: message.fileSize)));
      //}
    } else if (message.localFileName.isNotEmpty) {
      var res = await msgListProvider.getFile(message.localFileName,
          context: context);
      if (res.isNotEmpty) {
        var localFullName = await saveInDownloads(res, message.fileName);
        if (localFullName.isNotEmpty) {
          OpenFileInApp(localFullName);
        }
      }
    }
  }
}

Future<bool> createMessage(
    {required String text,
    required MsgListProvider msgListProvider,
    required Task? task, // task could be different from the current one
    bool isTaskDescriptionItem = false,
    bool isImage = false,
    String fileName = "",
    String tempID = "",
    bool loadinInProcess = false,
    MessageAction messageAction =
        MessageAction.CreateUpdateMessageAction}) async {
  if (sessionID == "" || task == null) {
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
    quotedText: msgListProvider.quotedText,
    parentsmallImageName: msgListProvider.parentsmallImageName,
    parentMessageID: msgListProvider.currentParentMessageID,
  );

  Response response;
  try {
    response = await httpClient.post(
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
    msgListProvider.addItem(message);
    //msgListProvider.taskID = tempID;
    msgListProvider.quotedText = "";
    msgListProvider.parentsmallImageName = "";
    msgListProvider.currentParentMessageID = 0;

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
      msgListProvider: msgListProvider,
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
      taskID: msgListProvider.taskID,
      text: text,
      fileName: path.basename(fileName),
      isImage: isImage,
      isTaskDescriptionItem: isTaskDescriptionItem,
      tempID: tempID);

  request.fields["Message"] = jsonEncode(message);
  request.files
      .add(http.MultipartFile.fromBytes("File", fileData, filename: fileName));

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

class NewMessageActionsMenu extends StatelessWidget {
  final MsgListProvider msgListProvider;

  const NewMessageActionsMenu({Key? key, required this.msgListProvider})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final task = msgListProvider.task as Task;

    List<PopupMenuItem> items = [
      /*CheckedPopupMenuItem<String>(
          value: "Done", checked: task.closed, child: const Text('Done')),
      CheckedPopupMenuItem<String>(
          value: "Closed", checked: task.closed, child: const Text('Closed')),*/
      if (!task.completed)
        PopupMenuItem(
            child: const Label(
              text: 'Done',
              backgroundColor: Colors.green,
              clickableCursor: true,
            ),
            onTap: () {
              createMessage(
                  text: "",
                  task: msgListProvider.task,
                  msgListProvider: msgListProvider,
                  messageAction: MessageAction.CompleteTaskAction);
              msgListProvider.task!.completed = true;
            }),
      if (task.completed)
        PopupMenuItem(
            child: const Text.rich(
                TextSpan(text: "Remove the ", children: <InlineSpan>[
              WidgetSpan(
                //baseline: TextBaseline.ideographic,
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
              createMessage(
                  text: "",
                  task: msgListProvider.task,
                  msgListProvider: msgListProvider,
                  messageAction: MessageAction.RemoveCompletedLabelAction);
              msgListProvider.task!.completed = false;
            }),
      if (!task.cancelled)
        PopupMenuItem(
            child: const Label(
              text: 'Cancel task',
              backgroundColor: Colors.grey,
              clickableCursor: true,
            ),
            onTap: () {
              createMessage(
                  text: "",
                  task: msgListProvider.task,
                  msgListProvider: msgListProvider,
                  messageAction: MessageAction.CancelTaskAction);
              msgListProvider.task!.cancelled = true;
            }),
      if (task.cancelled || task.closed)
        PopupMenuItem(
            child: const Label(
              text: 'Reopen task',
              backgroundColor: Colors.orange,
              clickableCursor: true,
            ),
            onTap: () {
              createMessage(
                  text: "",
                  task: msgListProvider.task,
                  msgListProvider: msgListProvider,
                  messageAction: MessageAction.ReopenTaskAction);
              msgListProvider.task!.cancelled = false;
              msgListProvider.task!.completed = false;
              msgListProvider.task!.closed = false;
            }),
    ];

    return PopupMenuButton(
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
      /*onSelected: (String result) {
        switch (result) {
          case "Closed":
            createMessage(
                text: "",
                msgListProvider: msgListProvider,
                messageAction: task.closed
                    ? MessageAction.ReopenTaskAction
                    : MessageAction.CloseTaskAction);
            task.closed = !task.closed;
            break;
          case "Done":
            createMessage(
                text: "",
                msgListProvider: msgListProvider,
                messageAction: task.completed
                    ? MessageAction.ReopenTaskAction
                    : MessageAction.CompleteTaskAction);
            task.completed = !task.completed;
            break;
        }
      },*/
    );
  }
}

FlutterSelectionControls messageSelectionControl(
    MsgListProvider msgListProvider,
    String? messageText,
    int messageID,
    FocusNode messageTextFieldFocusNode,
    BuildContext context) {
  return FlutterSelectionControls(toolBarItems: [
    ToolBarItem(
        item: const Text('Select All'),
        itemControl: ToolBarItemControl.selectAll),
    ToolBarItem(item: const Text('Copy'), itemControl: ToolBarItemControl.copy),
    ToolBarItem(
        item: const Text('Reply'),
        onItemPressed: (String highlightedText, int startIndex, int endIndex) {
          msgListProvider.quotedText = messageText ?? "";
          msgListProvider.currentParentMessageID = messageID;

          //messageTextFieldFocusNode.dispose();
          searchFocusNode.unfocus();
          messageTextFieldFocusNode = FocusNode();
          messageTextFieldFocusNode.requestFocus();
          msgListProvider.refresh();
        }),
    if (messageText != null)
      ToolBarItem(
          item: const Text('Quote selection'),
          onItemPressed:
              (String highlightedText, int startIndex, int endIndex) {
            msgListProvider.quotedText =
                messageText.substring(startIndex, endIndex);
            msgListProvider.currentParentMessageID = messageID;
            //messageTextFieldFocusNode.dispose();
            searchFocusNode.unfocus();
            messageTextFieldFocusNode = FocusNode();
            messageTextFieldFocusNode.requestFocus();
            msgListProvider.refresh();
          }),
    ToolBarItem(
        item: const Text('Delete'),
        onItemPressed:
            (String highlightedText, int startIndex, int endIndex) async {
          var res = await confirmDismissDlg(context);
          if (res ?? false) {
            msgListProvider.deleteMesage(messageID);
          }
        })
  ]);
}
