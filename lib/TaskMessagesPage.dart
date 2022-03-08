import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'MainMenu.dart';
import 'utils.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'LoginPage.dart';
import 'MsgList.dart';
import 'main.dart';
import 'dart:io';
import 'dart:convert';
import 'TasksPage.dart';
import 'package:file_picker/file_picker.dart';

//import 'package:web_socket_channel/web_socket_channel.dart';
//import 'package:web_socket_channel/status.dart' as status;

class TaskMessagesPage extends StatefulWidget {
  final Task task;

  const TaskMessagesPage({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskMessagesPage> createState() => _TaskMessagesPageState();
}

/*IOWebSocketChannel InitSocket() {
  return IOWebSocketChannel.connect('ws://' + server + "/initMessagesWS");
}*/

class _TaskMessagesPageState extends State<TaskMessagesPage> {
  late MsgListProvider _msgListProvider;

  final _messageInputController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

// This is what you're looking for!
  void _scrollDown() {
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }

  @override
  void initState() {
    super.initState();
    _msgListProvider = Provider.of<MsgListProvider>(context, listen: false);
    _msgListProvider.taskID = widget.task.ID;

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

    _scrollController.addListener(() {
      if (!_msgListProvider.loading &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent) {
        requestMessages();
      }
    });

    requestMessages();
  }

  @override
  void dispose() {
    super.dispose();
    _msgListProvider.clear();
    //ws.sink.close();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          //backgroundColor: Colors.black,
          title: Row(children: [
            TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.white,
                ),
                label: Text(
                  widget.task.Description,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                )),
          ]),
          leading: MainMenu()),
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
              return InifiniteMsgList(
                scrollController: _scrollController,
                onDelete: deleteMesage,
              );
            }),
            Row(children: [
              Expanded(
                  child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter,
                      control: false): () {
                    createMessage(text: _messageInputController.text);
                    _messageInputController.text = "";
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
                      border: OutlineInputBorder(),
                      hintText: 'Message',
                    ),
                  ),
                ),
              )),
              FloatingActionButton(
                onPressed: () {
                  createMessage(text: _messageInputController.text);
                  _messageInputController.text = "";
                },
                tooltip: 'New message',
                child: const Icon(Icons.message),
              ),
              IconButton(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();

                  if (result != null && result.files.single.path != null) {
                    //File file = File([], result.files.single.path as String);
                    var fileName = result.files.single.path;
                    var res = await readFile(result.files.single.path);
                    createMessage(
                        text: _messageInputController.text,
                        fileData: res,
                        fileName: fileName == null ? "" : fileName);
                    _messageInputController.text = "";
                  }
                },
                tooltip: 'Add file',
                icon: const Icon(Icons.attach_file),
              )
            ])
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

  Future<void> requestMessages() async {
    //List<Message> res = [];

    if (sessionID == "" || !mounted) {
      return;
    }

    var query = strMap("command", "getMessages");
    query["sessionID"] = sessionID;
    query["lastID"] = _msgListProvider.lastID.toString();
    query["limit"] = "30";
    query["taskID"] = widget.task.ID.toString();

    _msgListProvider.loading = true;
    ws.sink.add(jsonEncode(query));
  }

  Future<bool> createMessage(
      {required String text,
      Uint8List? fileData,
      String fileName = "",
      bool isPicture = false}) async {
    if (sessionID == "") {
      return false;
    }

    MultipartRequest request =
        MultipartRequest('POST', Uri.http(server, '/createMessage'));

    request.headers["sessionID"] = sessionID;
    request.headers["content-type"] = "application/json; charset=utf-8";

    Message message = Message(
        task: widget.task,
        text: text,
        fileName: fileName,
        isImage: isImageFile(fileName));

    request.fields["Message"] = jsonEncode(message);

    if (fileData != null) {
      request.files
          .add(MultipartFile.fromBytes("File", fileData, filename: fileName));
    }

    var streamedResponse = await request.send();
    if (streamedResponse.statusCode == 200) {
      /*Response response = await Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      message.ID = data["ID"];
      message.userID = data["UserID"];*/
      return true;
    }
    return false;
  }

  Future<void> requestMessages_() async {
    List<Message> res = [];

    if (sessionID == "" || !mounted) {
      return;
    }

    /* Map<String, String> headers = Map<String, String>();
    headers["sessionID"] = sessionID;
    //headers["offset"] = _msgListProvider.offset.toString();
    headers["lastID"] = _msgListProvider.lastID.toString();
    headers["limit"] = "30";
    headers["taskID"] = widget.task.ID.toString();
    headers["content-type"] = "application/json; charset=utf-8";*/

    _msgListProvider.loading = true;

    var response;
    Stopwatch stopwatch = new Stopwatch()..start();
    var client = HttpClient();

    MultipartRequest request =
        MultipartRequest('GET', Uri.http(server, '/messages'));

    request.headers["sessionID"] = sessionID;
    request.headers["lastID"] = _msgListProvider.lastID.toString();
    request.headers["limit"] = "30";
    request.headers["taskID"] = widget.task.ID.toString();

    request.headers["content-type"] = "application/json; charset=utf-8";

    var streamedResponse = await request.send();

    /*try {
      response =
          await httpClient.get(Uri.http(server, '/messages'), headers: headers);
    } catch (e) {
      return;
    }*/

    if (streamedResponse.statusCode == 200) {
      var response = await Response.fromStream(streamedResponse);
      var a = 1; // it is just a binary data, not a list of files
      toast('doSomething() executed in ${stopwatch.elapsed.inMilliseconds}',
          context);
    }

    /*if (response.statusCode == 200) {
      
      var data = jsonDecode(response.body);

      _msgListProvider.offset = _msgListProvider.offset + data.length;

      for (var e in data) {
        res.add(Message.fromJson(e));
      }
      if (data.length > 0)
        _msgListProvider.lastID = data[data.length - 1]["ID"];
    }*/

    _msgListProvider.loading = false;

    if (res.isEmpty) {
      return;
    }
    setState(
        () => _msgListProvider.items = [..._msgListProvider.items, ...res]);
  }

  Future<bool> deleteMesage(int messageID) async {
    if (sessionID == "") {
      return false;
    }

    Map<String, String> headers = Map<String, String>();
    headers["sessionID"] = sessionID;

    var response;

    try {
      response = await httpClient.delete(
          Uri.http(server, '/deleteMessage/' + messageID.toString()),
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
