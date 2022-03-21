//import 'dart:ffi';

import 'package:flutter/material.dart';
//import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'LoginPage.dart';
import 'SettingsPage.dart';
import 'utils.dart';
//import 'TaskMessagesPage.dart';
import 'TasksPage.dart';
import 'package:provider/provider.dart';
//import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

//import 'dart:io';
//import 'dart:async';

import 'MsgList.dart';
//import 'package:crypto/crypto.dart';

var httpClient = http.Client();
WebSocketChannel ws =
    WebSocketChannel.connect(Uri.parse('ws://' + server + "/initMessagesWS"));

String server = "";
//String todolist_server = server + "todo";
String sessionID = "";
int currentUserID = 0;

late SharedPreferences settings;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: MsgListProvider(),
        ),
        ChangeNotifierProvider.value(
          value: TasksListProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'ToDo Chat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MyHomePage(title: "ToDo Chat"),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MsgListProvider _msgListProvider;
  late TasksListProvider _tasksListProvider;

  @override
  void initState() {
    super.initState();
    _msgListProvider = Provider.of<MsgListProvider>(context, listen: false);
    _tasksListProvider = Provider.of<TasksListProvider>(context, listen: false);
    //Login(_tasksListProvider);
  }

  @override
  void dispose() {
    super.dispose();
    httpClient.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //appBar: AppBar(title: Text(widget.title), leading: MainMenu()),
        body: RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<bool>(
        future: initApp(context), // function where you call your api
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          // AsyncSnapshot<Your object type>
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: Text('Connecting to the server...',
                    textDirection: TextDirection.ltr));
          } else {
            if (snapshot.hasError) {
              //toast(snapshot.error.toString(), context);
              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Center(
                        child: IconButton(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh))),
                    const Spacer(),
                    ElevatedButton(
                        onPressed: () async {
                          bool res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsPage()),
                          );
                          setState(() {});
                        },
                        child: const Text("Settings")),
                  ]);
            } else if (snapshot.data as bool) {
              return const TasksPage();
            } else {
              return const Center(
                  child: Text('Надо вставить код',
                      textDirection: TextDirection.ltr));
            }
          }
        },
      ),
    ));

    /*Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body:
          const TasksPage(), /*Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<MsgListProvider>(builder: (context, provider, child) {
              return Expanded(
                  child: InifiniteList(
                      onRequest: requestItems,
                      itemBuilder: (context, item, index) {
                        return ChatBubble(
                          isCurrentUser: true,
                          text: item.text,
                        );
                      }));
            }),
          ],
        ),
      ),*/
    );*/
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  Future<bool> initApp(BuildContext context) async {
    bool res;

    settings = await SharedPreferences.getInstance();

    var serverRes = settings.getString("server");

    if (serverRes == null || serverRes.isEmpty) {
      res = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    } else {
      server = serverRes;
    }
    try {
      res = await login();
    } catch (e) {
      return Future.error(e.toString());
    }

    if (!res) {
      await openLoginPage(context);
    }

    if (sessionID.isNotEmpty) {
      var query = mapstr("command", "init");
      query["sessionID"] = sessionID;
      try {
        ws.sink.add(jsonEncode(query));
        ws.stream.listen((messageJson) {
          WSMessage wsMsg = WSMessage.fromJson(messageJson);
          if (wsMsg.command == "getMessages") {
            _msgListProvider.addItems(wsMsg.data);
          } else if (wsMsg.command == "createMessage") {
            var message = Message.fromJson(wsMsg.data);
            _msgListProvider.addItem(message);
          }
        });
      } catch (e) {
        print(e.toString());
      }
    }
    return true;
  }
}
