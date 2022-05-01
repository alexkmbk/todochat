import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'HttpClient.dart';
import 'LoginPage.dart';
import 'SettingsPage.dart';
import 'inifiniteTaskList.dart';
import 'utils.dart';
//import 'TaskMessagesPage.dart';
import 'TasksPage.dart';
import 'package:provider/provider.dart';
//import 'package:flutter/services.dart';
//import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'MsgList.dart';

var httpClient = HttpClient();
WebSocketChannel? ws;

Uri serverURI = Uri();
String sessionID = "";
int currentUserID = 0;
bool isDesktopMode = false;
bool appInitialized = false;
const Color completedTaskColor = Color.fromARGB(255, 183, 242, 176);
const Color uncompletedTaskColor = Color.fromARGB(255, 253, 253, 242);
late SharedPreferences settings;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var instance = WidgetsBinding.instance;
    if (instance != null) {
      var mediaQueryData = MediaQueryData.fromWindow(instance.window);
      var physicalPixelWidth = mediaQueryData.size.width;

      if (physicalPixelWidth > 1000) {
        //isDesktopMode = true;
      }
    }

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
          home: const MyHomePage(title: "ToDo Chat")),
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
    if (ws != null) {
      ws?.sink.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (appInitialized) {
      return const Scaffold(body: TasksPage());
    } else {
      return Scaffold(
        //appBar: AppBar(title: Text(widget.title), leading: MainMenu()),
        body: FutureBuilder<bool>(
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
      );
    }

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
    if (appInitialized) return true;
    bool res;

    settings = await SharedPreferences.getInstance();

    var httpScheme = settings.getString("httpScheme");
    var host = settings.getString("host");
    var port = settings.getInt("port");

    if (port == null || port == 0) {
      port = null;
    }
    var isServerURI = true;
    if (host == null || host.isEmpty) {
      isServerURI = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    } else {
      serverURI = Uri(scheme: httpScheme, host: host, port: port);
    }
    if (isServerURI) {
      ws = WebSocketChannel.connect(
          setUriProperty(serverURI, scheme: "ws", path: "initMessagesWS"));
      /*ws = WebSocketChannel.connect(
          Uri.parse('ws://' + serverURI.authority + "/initMessagesWS"));*/
    }
    try {
      res = await login();
    } catch (e) {
      return Future.error(e.toString());
    }

    if (!res) {
      await openLoginPage(context);
    }

    if (sessionID.isNotEmpty && ws != null) {
      try {
        ws!.sink.add(jsonEncode({"command": "init", "sessionID": sessionID}));
        ws!.stream.listen((messageJson) {
          WSMessage wsMsg = WSMessage.fromJson(messageJson);
          if (wsMsg.command == "getMessages") {
            _msgListProvider.addItems(wsMsg.data);
          } else if (wsMsg.command == "createMessage") {
            var message = Message.fromJson(wsMsg.data);
            _msgListProvider.addItem(message);
            _tasksListProvider.updateLastMessage(message.taskID, message);
          }
        });
      } catch (e) {
        if (kDebugMode) {
          print(e.toString());
        }
      }
    }
    appInitialized = true;
    return true;
  }
}
