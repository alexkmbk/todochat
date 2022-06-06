import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'HttpClient.dart';
import 'LoginPage.dart';
import 'ProjectsList.dart';
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
String currentUserName = "";
bool isDesktopMode = false;
bool appInitialized = false;
const Color closedTaskColor = Color.fromARGB(255, 183, 242, 176);
//const Color uncompletedTaskColor = Color.fromARGB(255, 248, 248, 147);
const Color uncompletedTaskColor = Colors.white;
const Color appBarColor = Color.fromARGB(240, 255, 255, 255);
const Color unreadTaskColor = Color.fromARGB(255, 250, 161, 27);
late SharedPreferences settings;

void main() {
  runApp(
    RestartWidget(
      builder: () {
        return const MyApp();
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
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var instance = WidgetsBinding.instance;
    var mediaQueryData = MediaQueryData.fromWindow(instance!.window);
    var physicalPixelWidth = mediaQueryData.size.width;
    if (physicalPixelWidth > 1000) {
      isDesktopMode = true;
    }

    return MultiProvider(
      //key: UniqueKey(),
      providers: [
        ChangeNotifierProvider.value(
          value: MsgListProvider(),
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
          )),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  //MsgListProvider msgListProvider;
  //TasksListProvider tasksListProvider;

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
      return const Scaffold(body: TasksPage());
    } else {
      return Scaffold(
        backgroundColor: closedTaskColor, //Colors.orange[600],
        //appBar: AppBar(title: Text(widget.title), leading: MainMenu()),
        body: FutureBuilder<bool>(
          future: initApp(context), // function where you call your api
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            // AsyncSnapshot<Your object type>
            if (snapshot.data != null && snapshot.data as bool) {
              return const TasksPage();
            } else {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    const SizedBox(
                      height: 50,
                    ),
                    const TextInCircle(
                      width: 150,
                      color: Colors.white,
                      textWidget: TextSpan(
                        children: [
                          TextSpan(
                              text: "ToDo\n",
                              style: TextStyle(
                                  color: closedTaskColor,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold)),
                          TextSpan(
                            text: "Chat",
                            style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 36,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
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
                      const Text('Connecting...',
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

  void listenWs(TasksListProvider taskListProvider) {
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);

    if (sessionID.isNotEmpty && ws != null) {
      try {
        subscription = ws!.stream.listen((messageJson) {
          WSMessage wsMsg = WSMessage.fromJson(messageJson);
          if (wsMsg.command == "getMessages") {
            msgListProvider.addItems(wsMsg.data);
          } else if (wsMsg.command == "createMessage") {
            var message = Message.fromJson(wsMsg.data);
            final created = msgListProvider.addItem(message);
            taskListProvider.updateLastMessage(
                message.taskID, message, created);
          } else if (wsMsg.command == "deleteMessage") {
            var message = Message.fromJson(wsMsg.data);
            msgListProvider.deleteItem(message.ID);
          } else if (wsMsg.command == "createTask") {
            var task = Task.fromJson(wsMsg.data);
            taskListProvider.addItem(task);
          } else if (wsMsg.command == "deleteTask") {
            var taskID = wsMsg.data;
            taskListProvider.deleteItem(taskID, context);
          } else if (wsMsg.command == "updateTask") {
            var task = Task.fromJson(wsMsg.data);
            taskListProvider.updateItem(task);
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

    /*final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);*/
    final taskListProvider =
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
      if (taskListProvider.projectID == null ||
          taskListProvider.projectID == 0) {
        taskListProvider.project = await requestFirstItem();
        if (taskListProvider.project != null) {
          taskListProvider.projectID = taskListProvider.project!.ID;
          await taskListProvider.requestTasks(context);
        }
      }

      if (taskListProvider.projectID != null &&
          taskListProvider.project == null) {
        taskListProvider.project = await getProject(taskListProvider.projectID);
        if (taskListProvider.project == null) {
          taskListProvider.project = await requestFirstItem();
          if (taskListProvider.project != null) {
            taskListProvider.projectID = taskListProvider.project!.ID;
            await taskListProvider.requestTasks(context);
          }
        }
      }
      connectWebSocketChannel(serverURI).then((value) {
        listenWs(taskListProvider);
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
              listenWs(taskListProvider);
            });
          } else {
            login().then((isLogin) async {
              if (isLogin) {
                connectWebSocketChannel(serverURI).then((value) {
                  connectWebSocketInProcess = false;
                  listenWs(taskListProvider);
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
