//import 'dart:ffi';

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'customWidgets.dart';
import 'inifiniteTaskList.dart';
import 'utils.dart';
import 'package:provider/provider.dart';
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
      //notifyListeners();
    }
    notifyListeners();
  }

  void addItem(Message message) {
    //offset++;
    //lastID = message.ID;
    if (message.taskID != taskID) {
      return;
    }
    if (items.firstWhereOrNull((element) => element.ID == message.ID) == null) {
      items.insert(0, message);
      notifyListeners();
    }
  }

  void deleteItem(int messageID) async {
    offset--;
    if (offset < 0) offset = 0;
    items.removeWhere((item) => item.ID == messageID);
    notifyListeners();
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
      this.isTaskDescriptionItem = false});

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
  }
}

typedef OnDeleteFn = Future<bool> Function(int messageID);

class InifiniteMsgList extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final ItemScrollController scrollController;

  final Future<bool> Function(int messageID) onDelete;
  final Future<Uint8List> Function(String localFileName) getFile;

  //final ItemBuilder itemBuilder;
  //final Task task;
  const InifiniteMsgList(
      {Key? key,
      required this.scrollController,
      required this.itemPositionsListener,
      required this.onDelete,
      required this.getFile})
      : super(key: key);

  @override
  InifiniteMsgListState createState() {
    return InifiniteMsgListState();
  }
}

class InifiniteMsgListState extends State<InifiniteMsgList> {
  late MsgListProvider _msgListProvider;

  @override
  void initState() {
    super.initState();

    _msgListProvider = Provider.of<MsgListProvider>(context, listen: false);
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
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (_msgListProvider.foundMessageID > 0 &&
          _msgListProvider.items.length > 1) {
        _msgListProvider.jumpTo(_msgListProvider.foundMessageID);
        _msgListProvider.foundMessageID = 0;
      }
    });

    return Expanded(
        child: Column(children: <Widget>[
      Expanded(
          child: ScrollablePositionedList.builder(
        reverse: true,
        itemScrollController: widget.scrollController,
        itemPositionsListener: widget.itemPositionsListener,
        itemCount: _msgListProvider.items.length,
        itemBuilder: (context, index) {
          var item = _msgListProvider.items[index];

          return ChatBubble(
            index: index,
            isCurrentUser: item.userID == currentUserID,
            message: item,
            msgListProvider: _msgListProvider,
            getFile: widget.getFile,
            onDismissed: (direction) async {
              if (await widget.onDelete(item.ID)) {
                _msgListProvider.deleteItem(item.ID);
              }
            },
          );
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
    ]));
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
        return DecoratedBox(
            decoration: BoxDecoration(
              color: msgListProvider.task!.Completed
                  ? completedTaskColor
                  : uncompletedTaskColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      msgListProvider.task!.authorName,
                      style: const TextStyle(color: Colors.blue),
                    )),
                Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      msgListProvider.task!.Description,
                    )),
              ]),
            ));
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
          serverURI.scheme +
              "://" +
              serverURI.authority +
              "/FileStorage/" +
              message.localFileName,
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

Future<bool> createMessage(
    {required String text,
    required int taskID,
    Uint8List? fileData,
    String fileName = "",
    bool isPicture = false,
    bool isTaskDescriptionItem = false}) async {
  if (sessionID == "") {
    return false;
  }

  MultipartRequest request = MultipartRequest(
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

  var streamedResponse = await request.send();
  if (streamedResponse.statusCode == 200) {
    return true;
  }
  return false;
}
