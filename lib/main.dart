import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'HttpClient.dart';
import 'LoginPage.dart';
import 'SettingsPage.dart';
import 'customWidgets.dart';
import 'inifiniteTaskList.dart';
import 'utils.dart';
//import 'TaskMessagesPage.dart';
import 'TasksPage.dart';
import 'package:provider/provider.dart';
//import 'package:flutter/services.dart';
//import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'MsgList.dart';

Uri serverURI = Uri();
String sessionID = "";
int currentUserID = 0;
bool isDesktopMode = false;
bool appInitialized = false;
const Color completedTaskColor = Color.fromARGB(255, 183, 242, 176);
const Color uncompletedTaskColor = Color.fromARGB(255, 248, 248, 147);
late SharedPreferences settings;

void main() {
  runApp(
    RestartWidget(
      builder: () {
        return MyApp();
      },
      beforeRestart: () {
        appInitialized = false;
        sessionID = "";
        if (ws != null) {
          ws!.sink.close(1001);
          ws = null;
          httpClient.close();
          isWSConnected = false;

          ///final context = getGlobalContext();
          /*if (context != null) {
            Provider.of<MsgListProvider>(context, listen: false).dispose();
          }*/
        }
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var instance = WidgetsBinding.instance;
    var mediaQueryData = MediaQueryData.fromWindow(instance!.window);
    var physicalPixelWidth = mediaQueryData.size.width;
    final msgListProvider = MsgListProvider();
    final tasksListProvider = TasksListProvider();
    if (physicalPixelWidth > 1000) {
      isDesktopMode = true;
    }

    return MultiProvider(
      //key: UniqueKey(),
      providers: [
        ChangeNotifierProvider.value(
          value: msgListProvider,
        ),
        ChangeNotifierProvider.value(
          value: TasksListProvider(),
        ),
      ],
      child: MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          title: 'ToDo Chat',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: MyHomePage(
            title: "ToDo Chat",
            msgListProvider: msgListProvider,
            tasksListProvider: tasksListProvider,
          )),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(
      {Key? key,
      required this.title,
      required this.msgListProvider,
      required this.tasksListProvider})
      : super(key: key);
  final String title;
  MsgListProvider msgListProvider;
  TasksListProvider tasksListProvider;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //late TasksListProvider _tasksListProvider;

  @override
  void initState() {
    super.initState();
    //msgListProvider = Provider.of<MsgListProvider>(context, listen: false);
    //_tasksListProvider = Provider.of<TasksListProvider>(context, listen: false);

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
      return Scaffold(
          body: TasksPage(
        msgListProvider: widget.msgListProvider,
      ));
    } else {
      return Scaffold(
        backgroundColor: completedTaskColor, //Colors.orange[600],
        //appBar: AppBar(title: Text(widget.title), leading: MainMenu()),
        body: FutureBuilder<bool>(
          future: initApp(context), // function where you call your api
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            // AsyncSnapshot<Your object type>
            if (snapshot.data != null && snapshot.data as bool) {
              return TasksPage(
                msgListProvider:
                    Provider.of<MsgListProvider>(context, listen: false),
              );
            } else {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    const SizedBox(
                      height: 50,
                    ),
                    const Text.rich(TextSpan(children: [
                      TextSpan(
                          text: "ToDo ",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 50,
                              fontWeight: FontWeight.bold)),
                      TextSpan(
                        text: "Chat",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                            fontWeight: FontWeight.bold),
                      )
                    ])),
                    const Spacer(),
                    if (snapshot.hasError)
                      IconButton(
                          iconSize: 40,
                          padding: const EdgeInsets.all(0.0),
                          onPressed: () => setState(() {}),
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                          )),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Text('Connecting to the server...',
                          style: TextStyle(color: Colors.white),
                          textDirection: TextDirection.ltr),
                    const Spacer(),
                    SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SettingsPage()),
                              );
                              setState(() {});
                            },
                            child: const Text(
                              "Settings",
                              style: TextStyle(fontSize: 16),
                            ))),
                    const SizedBox(
                      height: 30,
                    )
                  ]));
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

  StreamSubscription? subscription;

  void listenWs() {
    if (sessionID.isNotEmpty && ws != null) {
      try {
        subscription = ws!.stream.listen((messageJson) {
          WSMessage wsMsg = WSMessage.fromJson(messageJson);
          if (wsMsg.command == "getMessages") {
            widget.msgListProvider.addItems(wsMsg.data);
          } else if (wsMsg.command == "createMessage") {
            var message = Message.fromJson(wsMsg.data);
            final created = widget.msgListProvider.addItem(message);
            widget.tasksListProvider
                .updateLastMessage(message.taskID, message, created);
          } else if (wsMsg.command == "deleteMessage") {
            var message = Message.fromJson(wsMsg.data);
            widget.msgListProvider.deleteItem(message.ID);
          } else if (wsMsg.command == "createTask") {
            var task = Task.fromJson(wsMsg.data);
            widget.tasksListProvider.addItem(task);
          } else if (wsMsg.command == "deleteTask") {
            var taskID = wsMsg.data;
            widget.tasksListProvider.deleteItem(taskID);
          } else if (wsMsg.command == "updateTask") {
            var task = Task.fromJson(wsMsg.data);
            widget.tasksListProvider.updateItem(task);
          }
        }, onDone: () {
          isWSConnected = false;
          subscription!.cancel();
          /*checkLogin().then((value) async {
            if (value) {
//              subscription!.cancel();
              //connectWebSocketChannel(serverURI);
            } else {
              login().then((isLogin) async {
                if (isLogin) {
//                  subscription!.cancel();
                  //connectWebSocketChannel(serverURI);
                } else {
                  RestartWidget.restartApp();
                }
              });
            }
          }).onError((error, stackTrace) {
            RestartWidget.restartApp();
          });*/
        }, onError: (error) {
          if (kDebugMode) {
            print(error.toString());
          }
          RestartWidget.restartApp();
        });
      } catch (e) {
        if (kDebugMode) {
          print(e.toString());
        }
        Future.delayed(const Duration(seconds: 2))
            .then((value) => RestartWidget.restartApp());
      }
    }
  }

  Future<bool> initApp(BuildContext context) async {
    if (appInitialized) return true;
    bool res;

    widget.msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);
    widget.tasksListProvider =
        Provider.of<TasksListProvider>(context, listen: false);

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
    try {
      res = await login();
    } catch (e) {
      return Future.error(e.toString());
    }

    if (!res) {
      await openLoginPage(context);
    }
    if (isServerURI && sessionID.isNotEmpty) {
      connectWebSocketChannel(serverURI).then((value) {
        listenWs();
      });
    }

    var connectWebSocketInProcess = false;
    Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!connectWebSocketInProcess &&
          !isWSConnected &&
          isServerURI &&
          sessionID.isNotEmpty) {
        connectWebSocketInProcess = true;
        checkLogin().then((value) {
          if (value) {
            connectWebSocketChannel(serverURI).then((value) {
              connectWebSocketInProcess = false;
              listenWs();
            });
          } else {
            login().then((isLogin) async {
              if (isLogin) {
                connectWebSocketChannel(serverURI).then((value) {
                  connectWebSocketInProcess = false;
                  listenWs();
                });
              } else {
                RestartWidget.restartApp();
              }
            });
          }
        }).onError((error, stackTrace) {
          RestartWidget.restartApp();
        });
      }
    });

    appInitialized = true;
    return true;
  }
}
