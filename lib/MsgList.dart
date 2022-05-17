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
import 'customWidgets.dart';
import 'inifiniteTaskList.dart';
import 'utils.dart';
import 'package:path/path.dart' as path;
import 'main.dart';
import 'package:collection/collection.dart';

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
    for (var item in data) {
      var message = Message.fromJson(item);
      if (message.taskID == taskID) {
        items.add(message);
      }
    }
    loading = false;
    if (data.length > 0) {
      lastID = data[data.length - 1]["ID"];
    }
    notifyListeners();
  }

  void addItem(Message message) {
    if (message.taskID != taskID) {
      return;
    }
    if (message.tempID.isNotEmpty) {
      int foundIndex =
          items.indexWhere((element) => element.tempID == message.tempID);
      if (foundIndex >= 0) {
        items[foundIndex] = message;
      }
    } else if (message.loadingFile) {
      message.tempID = UniqueKey().toString();
      items.insert(0, message);
      notifyListeners();
    } else if (items.firstWhereOrNull((element) => element.ID == message.ID) ==
        null) {
      items.insert(0, message);
      notifyListeners();
    }
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
  Uint8List? loadingFileData;
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
      this.loadingFileData,
      this.tempID = ""});

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
            var item = widget.msgListProvider.items[index];
            if (item.loadingFile) {
              return LoadingFileBubble(
                index: index,
                isCurrentUser: item.userID == currentUserID,
                message: item,
                msgListProvider: widget.msgListProvider,
                getFile: widget.getFile,
              );
            } else {
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
          },
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
                          createMessage(
                              text: _messageInputController.text,
                              msgListProvider: widget.msgListProvider,
                              fileData: bytes,
                              fileName: "clipboard_image.bmp");
                        } else {
                          final files = await Pasteboard.files();
                          if (files.isNotEmpty) {
                            for (final file in files) {
                              var fileData = await readFile(file);
                              if (fileData.isNotEmpty) {
                                createMessage(
                                    text: _messageInputController.text,
                                    msgListProvider: widget.msgListProvider,
                                    fileData: fileData,
                                    fileName: file);
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
                                  var response = await get(Uri.parse(imageURL));
                                  if (response.statusCode == 200) {
                                    createMessage(
                                        text: "",
                                        msgListProvider: widget.msgListProvider,
                                        fileData: response.bodyBytes,
                                        fileName: "clipboard_image.png");
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
                        widget.msgListProvider.addItem(Message(
                            taskID: widget.msgListProvider.taskID,
                            userID: currentUserID,
                            fileName: fileName,
                            loadingFile: true,
                            loadingFileData: res,
                            isImage: isImageFile(fileName)));
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
  const ChatBubble(
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
              /*shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0))),*/
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
                        msgListProvider.task!.Description,
                      )),
                ]),
              )),
          const SizedBox(height: 5),
          const Text("***", style: TextStyle(color: Colors.grey)),
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
                  child: drawBubble(context, constraints)),
            ));
      }
    });
  }

  Widget drawBubble(BuildContext context, BoxConstraints constraints) {
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
      if (message.isImage && message.smallImageName.isNotEmpty) {
        return networkImage(
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
            // chat bubble decoration
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? Colors.blue
                  : const Color.fromARGB(255, 224, 224, 224),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GestureDetector(
              onTap: () => onTapOnFileMessage(message, context),
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
                      ])),
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

class LoadingFileBubble extends StatefulWidget {
  const LoadingFileBubble(
      {Key? key,
      required this.message,
      required this.getFile,
      required this.isCurrentUser,
      required this.msgListProvider,
      required this.index})
      : super(key: key);
  final Message message;
  final bool isCurrentUser;
  final MsgListProvider msgListProvider;
  final int index;
  /*final String text;
  final String isImage = false;
  final Uint8List? smallImageData;
  final bool isCurrentUser;*/
  final Future<Uint8List> Function(String localFileName) getFile;

  @override
  State<LoadingFileBubble> createState() => _LoadingFileBubbleState();
}

class _LoadingFileBubbleState extends State<LoadingFileBubble> {
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    if (!widget.message.loadinInProcess) {
      widget.message.loadinInProcess = true;
      createMessage(
          text: widget.message.text,
          fileData: widget.message.loadingFileData,
          fileName: widget.message.fileName,
          msgListProvider: widget.msgListProvider,
          tempID: widget.message.tempID,
          onProgress: (int bytes, int totalBytes) {
            setState(() {
              if (totalBytes == 0) {
                progress = 0.0;
              } else {
                progress = bytes / totalBytes;
              }
            });
          });
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        // asymmetric padding
        padding: EdgeInsets.fromLTRB(
          widget.isCurrentUser ? 64.0 : 16.0,
          4,
          widget.isCurrentUser ? 16.0 : 64.0,
          4,
        ),
        child: Align(
            // align the child within the container
            alignment: widget.message.isTaskDescriptionItem
                ? Alignment.center
                : widget.isCurrentUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
            child: drawBubble(context, constraints)),
      );
    });
  }

  Widget drawBubble(BuildContext context, BoxConstraints constraints) {
    if (widget.message.isImage && widget.message.loadingFileData != null) {
      return Stack(children: [
        memoryImage(
          widget.message.loadingFileData as Uint8List,
          height: 200,
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
      ]);
    } else {
      return Column(children: [
        DecoratedBox(
          // chat bubble decoration
          decoration: BoxDecoration(
            color: widget.isCurrentUser
                ? Colors.blue
                : const Color.fromARGB(255, 224, 224, 224),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.file_present_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    FittedBox(
                        fit: BoxFit.fill,
                        alignment: Alignment.center,
                        child: SelectableText(
                          widget.message.fileName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(
                                  color: widget.isCurrentUser
                                      ? Colors.white
                                      : Colors.black87),
                        )),
                  ])),
        ),
        if (progress < 1)
          LinearProgressIndicator(
            value: progress,
          )
      ]);
    }
  }
}

Future<bool> createMessage(
    {required String text,
    required MsgListProvider msgListProvider,
    Uint8List? fileData,
    String fileName = "",
    bool isPicture = false,
    bool isTaskDescriptionItem = false,
    Function(int bytes, int totalBytes)? onProgress,
    String tempID = ""}) async {
  if (sessionID == "") {
    return false;
  }

  final request = HTTPClient.MultipartRequest(
    'POST',
    setUriProperty(serverURI, path: 'createMessage'),
    onProgress: onProgress,
  );

  request.headers["sessionID"] = sessionID;
  request.headers["content-type"] = "application/json; charset=utf-8";

  Message message = Message(
      taskID: msgListProvider.taskID,
      text: text,
      fileName: path.basename(fileName),
      isImage: isImageFile(fileName),
      isTaskDescriptionItem: isTaskDescriptionItem,
      tempID: tempID);

  request.fields["Message"] = jsonEncode(message);
  if (fileData != null) {
    request.files.add(
        http.MultipartFile.fromBytes("File", fileData, filename: fileName));
  }

  final streamedResponse = await request.send();

  /* MultipartRequest request = MultipartRequest(
      'POST', setUriProperty(serverURI, path: 'createMessage'));

  request.headers["sessionID"] = sessionID;
  request.headers["content-type"] = "application/json; charset=utf-8";

  Message message = Message(
      taskID: taskID,
      text: text,
      fileName: path.basename(fileName),
      isImage: isImageFile(fileName),
      isTaskDescriptionItem: isTaskDescriptionItem);

  request.fields["Message"] = jsonEncode(message);

  if (fileData != null) {
    request.files
        .add(MultipartFile.fromBytes("File", fileData, filename: fileName));
  }

  var streamedResponse = await request.send();*/
  if (streamedResponse.statusCode == 200) {
    return true;
  }
  return false;
}
