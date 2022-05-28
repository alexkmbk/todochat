//import 'dart:ffi';

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:pasteboard/pasteboard.dart';
//import 'package:http/http.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'HttpClient.dart' as HTTPClient;
import 'package:http/http.dart' as http;
import 'HttpClient.dart';
import 'customWidgets.dart';
import 'inifiniteTaskList.dart';
import 'utils.dart';
import 'package:path/path.dart' as path;
import 'main.dart';
import 'package:collection/collection.dart';

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
  int taskID = 0;
  Task? task;
  int foundMessageID = 0;
  ItemScrollController? scrollController;

  void jumpTo(int messageID) {
    if (messageID == 0) return;
    var index = items.indexWhere((element) => element.ID == messageID);
    if (index >= 0 && scrollController != null) {
      scrollController!.jumpTo(index: index);
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
    if (notify) {
      notifyListeners();
    }
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
    notifyListeners();
  }

  bool addItem(Message message) {
    if (message.taskID != taskID) {
      return false;
    }
    bool created = false;
    if (message.tempID.isNotEmpty && message.userID == currentUserID) {
      int foundIndex =
          items.indexWhere((element) => element.tempID == message.tempID);
      if (foundIndex >= 0) {
        /*final request = uploadingFiles[message.tempID];
        if (request != null && request.loadingFileData.isNotEmpty) {
          message.loadingFileData = request.loadingFileData;
        }*/
        items[foundIndex] = message;
      } else if (!message.loadinInProcess) {
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
      } else if (message.tempID.isNotEmpty &&
          message.userID != currentUserID &&
          !message.loadinInProcess &&
          foundItem != null) {
        items[items.indexOf(foundItem)] = message;
        notifyListeners();
      }
    }
    return created;
  }

  void deleteItem(int messageID) async {
    items.removeWhere((item) => item.ID == messageID);
    notifyListeners();
  }

  void requestMessages() async {
    if (ws == null) {
      await Future.delayed(const Duration(seconds: 2));
    }
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
    // }
  }
}

class Message {
  int ID = 0;
  int taskID = 0;
  int projectID = 0;
  Task? task;
  DateTime? created_at;
  String text = "";
  int userID = 0;
  String userName = "";
  String fileName = "";
  int fileSize = 0;
  String localFileName = "";
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

  Message(
      {required this.taskID,
      this.text = "",
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
      this.loadinInProcess = false});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'taskID': taskID == 0 ? task?.ID : taskID,
      'projectID': projectID,
      'created_at': created_at,
      'text': text,
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
    };
  }

  Message.fromJson(Map<String, dynamic> json) {
    ID = json['ID'];
    created_at = DateTime.tryParse(json['Created_at']);
    text = json['Text'];
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
    var value = json['IsTaskDescriptionItem'];
    isTaskDescriptionItem = value ?? false;
    tempID = json["TempID"];
    loadinInProcess = json["LoadinInProcess"];
  }
}

typedef OnDeleteFn = Future<bool> Function(int messageID);

class InifiniteMsgList extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final ItemScrollController scrollController;

  final Future<bool> Function(int messageID) onDelete;
  final Future<Uint8List> Function(String localFileName) getFile;
  final MsgListProvider msgListProvider;

  //final ItemBuilder itemBuilder;
  //final Task task;
  const InifiniteMsgList(
      {Key? key,
      required this.scrollController,
      required this.itemPositionsListener,
      required this.onDelete,
      required this.getFile,
      required this.msgListProvider})
      : super(key: key);

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

  @override
  void initState() {
    super.initState();

    //_msgListProvider = Provider.of<MsgListProvider>(context, listen: false);
    //getMoreItems();
    /*WidgetsBinding.instance?.addPostFrameCallback((_) {
      getMoreItems();
    });*/

/*    _scrollController.addListener(() {
      if (!_msgListProvider.loading &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent) getMoreItems();
    });*/
  }

/*  InifiniteListState() {
    _controller.addListener(() {
      _getMoreItems();
    });
  }*/

  /*final ScrollController _scrollController = ScrollController();
// This is what you're looking for!
  void _scrollDown() {
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }*/

  @override
  Widget build(BuildContext context) {
    if (widget.msgListProvider.task == null ||
        widget.msgListProvider.task?.ID == 0) {
      return const Center(child: Text("No any task was selected"));
    } else {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        if (widget.msgListProvider.foundMessageID > 0 &&
            widget.msgListProvider.items.length > 1) {
          widget.msgListProvider.jumpTo(widget.msgListProvider.foundMessageID);
          widget.msgListProvider.foundMessageID = 0;
        }
      });

      return Expanded(
          child: Column(children: <Widget>[
        Expanded(
            child: ScrollablePositionedList.builder(
                reverse: true,
                itemScrollController: widget.scrollController,
                itemPositionsListener: widget.itemPositionsListener,
                itemCount: widget.msgListProvider.items.length,
                itemBuilder: (context, index) {
                  if (widget.msgListProvider.items.isEmpty) {
                    return const Text("");
                  }
                  var item = widget.msgListProvider.items[index];
                  /*if (item.tempID.isNotEmpty && item.loadinInProcess) {
              return LoadingFileBubble(
                index: index,
                isCurrentUser: item.userID == currentUserID,
                message: item,
                msgListProvider: widget.msgListProvider,
                getFile: widget.getFile,
              );
            } else {*/
                  return ChatBubble(
                    index: index,
                    isCurrentUser: item.userID == currentUserID,
                    message: item,
                    msgListProvider: widget.msgListProvider,
                    getFile: widget.getFile,
                    onDismissed: (direction) async {
                      if (await widget.onDelete(item.ID)) {
                        widget.msgListProvider.deleteItem(item.ID);
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
                )),
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
                child: Row(children: [
                  Expanded(
                      child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter,
                          control: false): () {
                        if (_messageInputController.text.isNotEmpty) {
                          createMessage(
                            text: _messageInputController.text,
                            msgListProvider: widget.msgListProvider,
                          );
                          _messageInputController.text = "";
                        }
                      },
                      const SingleActivator(LogicalKeyboardKey.keyV,
                          control: true): () async {
                        final bytes = await Pasteboard.image;
                        if (bytes != null) {
                          widget.msgListProvider.addUploadingItem(
                              Message(
                                  taskID: widget.msgListProvider.taskID,
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
                                widget.msgListProvider.addUploadingItem(
                                    Message(
                                        taskID: widget.msgListProvider.taskID,
                                        userID: currentUserID,
                                        fileName: path.basename(file),
                                        loadingFile: true,
                                        isImage: isImageFile(file)),
                                    fileData);
                              }
                            }
                          } else {
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
                              var html = await Pasteboard.html;
                              if (html != null && html.isNotEmpty) {
                                String imageURL = getImageURLFromHTML(html);
                                if (imageURL.isNotEmpty) {
                                  var response;
                                  try {
                                    response = await get(Uri.parse(imageURL));
                                  } catch (e) {
                                    toast(e.toString(), context);
                                    return;
                                  }

                                  if (response.statusCode == 200) {
                                    widget.msgListProvider.addUploadingItem(
                                        Message(
                                            taskID:
                                                widget.msgListProvider.taskID,
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
                    child: Focus(
                      autofocus: true,
                      child: TextField(
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
                  )),
                  IconButton(
                    onPressed: () {
                      if (_messageInputController.text.isNotEmpty) {
                        createMessage(
                            text: _messageInputController.text,
                            msgListProvider: widget.msgListProvider);
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

                      var fileName = result?.files.single.path?.trim() ?? "";

                      if (fileName.isNotEmpty) {
                        var res = await readFile(fileName);
                        widget.msgListProvider.addUploadingItem(
                            Message(
                                taskID: widget.msgListProvider.taskID,
                                userID: currentUserID,
                                fileName: path.basename(fileName),
                                loadingFile: true,
                                isImage: isImageFile(fileName)),
                            res);
                        _messageInputController.text = "";
                      }
                    },
                    tooltip: 'Add file',
                    icon: const Icon(Icons.attach_file),
                  )
                ])))
      ]));
    }
  }
}

class ChatBubble extends StatelessWidget {
  ChatBubble(
      {Key? key,
      required this.message,
      required this.onDismissed,
      required this.getFile,
      required this.isCurrentUser,
      required this.msgListProvider,
      required this.index})
      : super(key: key);
  final Message message;
  final bool isCurrentUser;
  final MsgListProvider msgListProvider;
  final int index;
  double progress = 1.0;
  /*final String text;
  final String isImage = false;
  final Uint8List? smallImageData;
  final bool isCurrentUser;*/
  final DismissDirectionCallback onDismissed;
  final Future<Uint8List> Function(String localFileName) getFile;

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
    if (foundStruct != null && foundStruct.multipartRequest == null) {
      createMessageWithFile(
          text: message.text,
          fileData: foundStruct.loadingFileData,
          fileName: message.fileName,
          msgListProvider: msgListProvider,
          tempID: message.tempID,
          onProgress: (int bytes, int totalBytes) {
            //setState(() {
            if (totalBytes == 0) {
              progress = 0.0;
            } else {
              progress = bytes / totalBytes;
            }
            //});
          });
    }
    return LayoutBuilder(builder: (context, constraints) {
      if (message.isTaskDescriptionItem && msgListProvider.task != null) {
        return Column(children: [
          /*Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Created by ${msgListProvider.task!.authorName} at ${dateFormat(msgListProvider.task!.Creation_date)}",
                style: const TextStyle(color: Colors.grey),
              )),*/
          //const SizedBox(height: 5),
          Card(
              color: msgListProvider.task!.Completed
                  ? completedTaskColor
                  : uncompletedTaskColor,
              shape: const BeveledRectangleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Created by ${msgListProvider.task!.authorName} at ${dateFormat(msgListProvider.task!.Creation_date)}",
                        style: const TextStyle(color: Colors.grey),
                      )),
                  const SizedBox(height: 5),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        msgListProvider.task?.Description ?? "",
                        style: const TextStyle(fontSize: 14),
                      )),
                ]),
              )),
          const SizedBox(height: 10),
          //const Text("***", style: TextStyle(color: Colors.grey)),
        ]);
      } else {
        return Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.startToEnd,
            confirmDismiss: (direction) {
              return confirmDimissDlg(
                  "Are you sure you wish to delete this item?", context);
            },
            onDismissed: onDismissed,
            child: Padding(
              // asymmetric padding
              padding: EdgeInsets.fromLTRB(
                isCurrentUser ? 64.0 : 16.0,
                4,
                isCurrentUser ? 16.0 : 64.0,
                4,
              ),
              child: Align(
                  // align the child within the container
                  alignment: message.isTaskDescriptionItem
                      ? Alignment.center
                      : isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: drawBubble(
                      context, constraints, foundStruct?.loadingFileData)),
            ));
      }
    });
  }

  Widget drawBubble(BuildContext context, BoxConstraints constraints,
      Uint8List? loadingFileData) {
    if (message.fileName.isEmpty) {
      final textSpan = TextSpan(text: message.text);
      final textWidget = SelectableText.rich(textSpan);
      /*final TextBox? lastBox =
          calcLastLineEnd(message.text, textSpan, context, constraints);
      bool fitsLastLine = false;
      if (lastBox != null) {
        fitsLastLine =
            constraints.maxWidth - lastBox.right > Timestamp.size.width + 10.0;
      }*/

      return DecoratedBox(
        // chat bubble decoration
        decoration: BoxDecoration(
          color: isCurrentUser
              ? const Color.fromARGB(255, 187, 239, 251)
              : const Color.fromARGB(255, 224, 224, 224),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: IntrinsicWidth(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  if (message.userName.isNotEmpty &&
                      (index == msgListProvider.items.length - 1 ||
                          msgListProvider.items[index + 1].userID !=
                              message.userID))
                    Text(
                      message.userName,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  Stack(children: [
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
                ]))),
      );
    } else {
      if (message.isImage &&
          (message.smallImageName.isNotEmpty || loadingFileData != null)) {
        return loadingFileData != null
            ? Stack(children: [
                memoryImage(
                  loadingFileData,
                  height: 200,
                  onTap: () => onTapOnFileMessage(message, context),
                ),
                if (progress < 1)
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
            : networkImage(
                serverURI.scheme +
                    '://' +
                    serverURI.authority +
                    "/FileStorage/" +
                    message.smallImageName,
                headers: {"sessionID": sessionID}, onTap: () {
                onTapOnFileMessage(message, context);
              },
                width: message.smallImageWidth.toDouble(),
                height: message.smallImageHeight.toDouble(),
                previewImageData: message.previewSmallImageData);
      } else {
        return DecoratedBox(
            // attached file
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? Colors.blue
                  : const Color.fromARGB(255, 224, 224, 224),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GestureDetector(
              onTap: () => onTapOnFileMessage(message, context),
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
                                      .bodyText1!
                                      .copyWith(
                                          color: isCurrentUser
                                              ? Colors.white
                                              : Colors.black87),
                                )),
                            if (progress < 1)
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
            ));
      }
    }
  }

  void onTapOnFileMessage(Message message, context) async {
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
      var res = await getFile(message.localFileName);
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
    bool isTaskDescriptionItem = false,
    bool isImage = false,
    String fileName = "",
    String tempID = "",
    bool loadinInProcess = false}) async {
  if (sessionID == "") {
    return false;
  }

  Message message = Message(
      taskID: msgListProvider.taskID,
      text: text,
      fileName: path.basename(fileName),
      isImage: isImage,
      isTaskDescriptionItem: isTaskDescriptionItem,
      tempID: tempID,
      loadinInProcess: loadinInProcess);

  Response response;
  try {
    response = await httpClient.post(
        setUriProperty(serverURI, path: 'createMessage'),
        body: jsonEncode(message));
  } catch (e) {
    return false;
  }
  //request.headers.contentLength = utf8.encode(body).length;

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body) as Map<String, dynamic>;

    Message message = Message.fromJson(data);
    msgListProvider.addItem(message);
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
    Function(int bytes, int totalBytes)? onProgress,
    required String tempID}) async {
  if (sessionID == "" || fileData == null) {
    return false;
  }

  final foundUploadingFile = uploadingFiles[tempID];
  if (foundUploadingFile == null) {
    return false;
  }

  if (onProgress != null && fileData != null) {
    onProgress(1, fileData.length);
  }

  bool isImage = isImageFile(fileName);

  final res = await createMessage(
      text: text,
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
    onProgress: onProgress,
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
