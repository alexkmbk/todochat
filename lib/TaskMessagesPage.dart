import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'HttpClient.dart' as HTTPClient;
import 'MainMenu.dart';
import 'utils.dart';
import 'package:provider/provider.dart';
import 'MsgList.dart';
import 'main.dart';
//import 'dart:io';
import 'inifiniteTaskList.dart';

//import 'package:web_socket_channel/web_socket_channel.dart';
//import 'package:web_socket_channel/status.dart' as status;

class TaskMessagesPage extends StatefulWidget {
  final Task task;
  //final MsgListProvider msgListProvider;

  const TaskMessagesPage({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskMessagesPage> createState() {
    return _TaskMessagesPageState();
  }
}

/*IOWebSocketChannel InitSocket() {
  return IOWebSocketChannel.connect('ws://' + server + "/initMessagesWS");
}*/

class _TaskMessagesPageState extends State<TaskMessagesPage> {
  final _messageInputController = TextEditingController();

  final ScrollController scrollController = ScrollController();
  final ItemScrollController itemsScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

// This is what you're looking for!
  /* void _scrollDown() {
    _scrollController.jumpTo(index: _msgListProvider.items.length - 1);
  }*/

  /*void _jumpTo(int messageID) {
    if (messageID == 0) return;
    var index =
        _msgListProvider.items.indexWhere((element) => element.ID == messageID);
    if (index >= 0) {
      _scrollController.jumpTo(index: index);
    }
  }*/

  @override
  void initState() {
    super.initState();

    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    msgListProvider.taskID = widget.task.ID;
    msgListProvider.task = widget.task;
    msgListProvider.foundMessageID = widget.task.lastMessageID;
    msgListProvider.scrollController = itemsScrollController;
    /*_msgListProvider.addListener(() {
      _jumpTo(widget.task.lastMessageID);
    });*/

/*    var query = strMap("command", "init");
    query["sessionID"] = sessionID;

    ws.sink.add(jsonEncode(query));
    ws.stream.listen((messageJson) {
      WSMessage wsMsg = WSMessage.fromJson(messageJson);
      if (wsMsg.command == "getMessages") {
        _msgListProvider.addItems(wsMsg.data, widget.task.ID);
      } else if (wsMsg.command == "createMessage") {
        var message = Message.fromJson(wsMsg.data);
        if (message.taskID == widget.task.ID) {
          _msgListProvider.addItem(message);
          //_scrollDown();
        }
      }
    });*/

    /*itemPositionsListener.itemPositions.addListener(() {
      if (!_msgListProvider.loading &&
          (itemPositionsListener.itemPositions.value.isEmpty ||
              (itemPositionsListener.itemPositions.value.last.index >=
                  _msgListProvider.items.length - 10))) {
        requestMessages();
      }
    });*/

    /*document.onPaste.listen((ClipboardEvent e) {
      var blob = e.clipboardData?.items?[0].getAsFile();
    });*/
    msgListProvider.requestMessages();
    //requestMessages(msgListProvider, widget.task.lastMessageID);
  }

  @override
  void dispose() {
    super.dispose();
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    msgListProvider.clear();

    //ws.sink.close();
    //_scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    return Scaffold(
      appBar: isDesktopMode
          ? null
          : AppBar(
              backgroundColor: const Color.fromARGB(240, 255, 255, 255),
              title: Row(children: [
                Flexible(
                    child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_left,
                          color: Colors.black,
                        ),
                        label: Text(
                          widget.task.description,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          //softWrap: false,
                          //style: Theme.of(context).textTheme.body1,
                        ))),
              ]),
              leading: const MainMenu()),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /* SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(widget.task.Description),
                )),*/
            Consumer<MsgListProvider>(builder: (context, provider, child) {
              return NotificationListener<ScrollUpdateNotification>(
                child: InifiniteMsgList(
                  scrollController: itemsScrollController,
                  itemPositionsListener: itemPositionsListener,
                  onDelete: deleteMesage,
                  getFile: getFile,
                ),
                onNotification: (notification) {
                  if (!provider.loading &&
                      (itemPositionsListener.itemPositions.value.isEmpty ||
                          (itemPositionsListener
                                  .itemPositions.value.last.index >=
                              provider.items.length - 10))) {
                    msgListProvider.requestMessages();
                  }
                  return true;
                },
              );
            }),
          ],
        ),
      ), /*Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Go back!'),
        ),
      ),*/
    );
  }

  Future<Uint8List> getFile(String localFileName) async {
    Uint8List res = Uint8List(0);
    if (sessionID == "" || !mounted) {
      return res;
    }

    MultipartRequest request = MultipartRequest(
        'GET',
        HTTPClient.setUriProperty(serverURI,
            path: 'getFile',
            queryParameters: {"localFileName": localFileName}));

    request.headers["sessionID"] = sessionID;
    request.headers["content-type"] = "application/json; charset=utf-8";

    var streamedResponse = await request.send();
    if (streamedResponse.statusCode == 200) {
      try {
        Response response = await Response.fromStream(streamedResponse);
        res = response.bodyBytes;
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

  Future<bool> deleteMesage(int messageID) async {
    if (sessionID == "") {
      return false;
    }

    Map<String, String> headers = <String, String>{};
    headers["sessionID"] = sessionID;

    Response response;

    try {
      response = await HTTPClient.httpClient.delete(
          HTTPClient.setUriProperty(serverURI, path: 'deleteMessage/$messageID')
          /*  Uri.http(
              serverURI.authority, '/deleteMessage/' + messageID.toString())*/
          ,
          headers: headers);
    } catch (e) {
      return false;
    }

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }
}
