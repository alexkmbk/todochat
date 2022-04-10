//import 'dart:ffi';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'customWidgets.dart';
import 'utils.dart';
import 'package:provider/provider.dart';

import 'TasksPage.dart';
import 'main.dart';

class MsgListProvider extends ChangeNotifier {
  List<Message> items = [];
  num offset = 0;
  int lastID = 0;
  bool loading = false;
  int taskID = 0;

  void clear() {
    items.clear();
    offset = 0;
    lastID = 0;
    taskID = 0;
  }

  void addItems(dynamic data) {
    for (var item in data) {
      var message = Message.fromJson(item);
      if (message.taskID == taskID) {
        items.add(message);
      }
    }
    if (data.length > 0) lastID = data[data.length - 1]["ID"];
    loading = false;
    notifyListeners();
  }

  void addItem(Message message) {
    //offset++;
    //lastID = message.ID;
    if (message.taskID != taskID) {
      return;
    }
    items.insert(0, message);
    notifyListeners();
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
  String fileName = "";
  int fileSize = 0;
  String localFileName = "";
  String smallImageName = "";
  bool isImage = false;

  Message(
      {required this.task,
      this.text = "",
      this.created_at,
      this.ID = 0,
      this.userID = 0,
      this.smallImageName = "",
      this.localFileName = "",
      this.fileName = "",
      this.isImage = false});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'taskID': task?.ID,
      'projectID': projectID,
      'created_at': created_at,
      'text': text,
      'userID': userID,
      'fileName': fileName,
      'fileSize': fileSize,
      'isImage': isImage,
      'smallImageName': smallImageName,
      'localFileName': localFileName,
    };
  }

  Message.fromJson(Map<String, dynamic> json) {
    ID = json['ID'];
    created_at = DateTime.tryParse(json['Created_at']);
    text = json['Text'];
    taskID = json['TaskID'];
    projectID = json['ProjectID'];
    userID = json['UserID'];
    isImage = json['IsImage'];
    fileName = json['FileName'];
    fileSize = json['FileSize'];
    smallImageName = json['SmallImageName'];
    localFileName = json['LocalFileName'];
  }
}

typedef OnDeleteFn = Future<bool> Function(int messageID);

class InifiniteMsgList extends StatefulWidget {
  final ScrollController scrollController;
  final Future<bool> Function(int messageID) onDelete;
  final Future<Uint8List> Function(String localFileName) getFile;

  //final ItemBuilder itemBuilder;
  //final Task task;
  const InifiniteMsgList(
      {Key? key,
      required this.scrollController,
      required this.onDelete,
      required this.getFile})
      : super(key: key);

  @override
  InifiniteMsgListState createState() {
    InifiniteMsgListState state = InifiniteMsgListState();
    return state;
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
    return Expanded(
        child: Column(children: <Widget>[
      Expanded(
          child: ListView.builder(
        reverse: true,
        controller: widget.scrollController,
        itemBuilder: (context, index) {
          //if (index < _msgListProvider.items.length) {
          var item = _msgListProvider.items[index];

          return ChatBubble(
            isCurrentUser: item.userID == currentUserID,
            message: item,
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
        itemCount: _msgListProvider.items.length,
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
      required this.isCurrentUser})
      : super(key: key);
  final Message message;
  final bool isCurrentUser;

  /*final String text;
  final String isImage = false;
  final Uint8List? smallImageData;
  final bool isCurrentUser;*/
  final DismissDirectionCallback onDismissed;
  final Future<Uint8List> Function(String localFileName) getFile;

  @override
  Widget build(BuildContext context) {
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
              alignment:
                  isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: drawBubble(context)),
        ));
  }

  Widget drawBubble(BuildContext context) {
    if (message.fileName.isEmpty) {
      return DecoratedBox(
        // chat bubble decoration
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            message.text,
            style: Theme.of(context)
                .textTheme
                .bodyText1!
                .copyWith(color: isCurrentUser ? Colors.white : Colors.black87),
          ),
        ),
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
        });
      } else {
        return DecoratedBox(
            // chat bubble decoration
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
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
