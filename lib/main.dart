import 'dart:async';
import 'package:flutter/material.dart';
import 'HttpClient.dart';
import 'LoginPage.dart';
import 'ProjectsList.dart';
import 'SettingsPage.dart';
import 'customWidgets.dart';
import 'inifiniteTaskList.dart';
import 'TasksPage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'MsgList.dart';
import 'todochat.dart';
import 'package:google_fonts/google_fonts.dart';

Timer? timer;

void main() {
  runApp(
    RestartWidget(
      builder: () {
        return const MyApp();
      },
      beforeRestart: () {
        if (timer != null) {
          timer!.cancel();
        }
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
            textTheme: Theme.of(context).textTheme.apply(
                  fontSizeFactor: 1.1,
                  fontSizeDelta: 2.0,
                ),
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
        backgroundColor: Colors.transparent, //Colors.orange[600],
        //appBar: AppBar(title: Text(widget.title), leading: MainMenu()),
        body: FutureBuilder<bool>(
          future: initApp(context), // function where you call your api
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            // AsyncSnapshot<Your object type>
            if (snapshot.data != null && snapshot.data as bool) {
              return const TasksPage();
            } else {
              return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromARGB(255, 50, 74, 228), //Color(0xFF3366FF),
                          Color.fromARGB(
                              255, 144, 184, 240), //Color(0xFF00CCFF),
                        ],
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp),
                  ),
                  child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 50,
                          ),
                          RichText(
                              text: TextSpan(children: [
                            TextSpan(
                              text: "ToDo\n",
                              style: GoogleFonts.comingSoon(
                                  fontSize: 48, color: Colors.green),
                            ),
                            TextSpan(
                              text: "Chat",
                              style: GoogleFonts.comingSoon(
                                  height: 1.0,
                                  fontSize: 48,
                                  color: Colors.orangeAccent),
                              //00116d
                              //1a6ce3
                              /*TextStyle(
                                height: 1.0,
                                color: Colors.orangeAccent,
                                fontSize: 50,
                                fontWeight: FontWeight.bold)*/
                            ),
                          ])),
                          /*TextInCircle(
                            width: 150,
                            color: Colors.white,
                            textWidget: TextSpan(
                              children: [
                                TextSpan(
                                  text: "ToDo\n",
                                  style: GoogleFonts.pacifico(
                                      fontSize: 48, color: closedTaskColor),
                                ),
                                TextSpan(
                                  text: "Chat",
                                  style: GoogleFonts.pacifico(
                                      height: 1.0,
                                      fontSize: 48,
                                      color: Colors.orangeAccent),
                                  //00116d
                                  //1a6ce3
                                  /*TextStyle(
                                height: 1.0,
                                color: Colors.orangeAccent,
                                fontSize: 50,
                                fontWeight: FontWeight.bold)*/
                                )
                              ],
                            ),
                          ),*/
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Text('Connecting...',
                                style: TextStyle(color: Colors.white),
                                textDirection: TextDirection.ltr),
                          const Spacer(),
                          SizedBox(
                              width: 200,
                              height: 50,
                              child: ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.orangeAccent)),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => SettingsPage(
                                                key: UniqueKey(),
                                                restartAppOnChange: true,
                                              )),
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
                        ]),
                  ));
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

    /* final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);*/
    final taskListProvider =
        Provider.of<TasksListProvider>(context, listen: false);

    settings = await SharedPreferences.getInstance();

    var httpScheme = settings.getString("httpScheme");
    var host = settings.getString("host");
    var port = settings.getInt("port");
    taskListProvider.projectID = settings.getInt("projectID");

    taskListProvider.showCompleted = settings.getBool("showCompleted") ?? true;

    if (port == null || port == 0) {
      port = null;
    }
    //var isServerURI = true;
    if (host == null || host.isEmpty) {
      isServerURI = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SettingsPage(
                  key: UniqueKey(),
                  restartAppOnChange: false,
                )),
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
        taskListProvider.project ??= await requestFirstItem();
      }
      if (taskListProvider.project != null) {
        taskListProvider.projectID = taskListProvider.project!.ID;
        await taskListProvider.requestTasks(context);
      }

      connectWebSocketChannel(serverURI).then((value) {
        listenWs(taskListProvider, context);
      });
    }

    // int counter = 0;
    //var connectWebSocketInProcess = false;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      reconnect(taskListProvider, context);

      /* counter++;
      createMessage(
          text: counter.toString(),
          msgListProvider: msgListProvider,
          task: Task(ID: 1));*/
      /*if (!connectWebSocketInProcess &&
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
      }*/
    });

    appInitialized = true;

    return true;
  }
}



/*void _incomingLinkHandler() {
  // 1
  if (!kIsWeb) {
    // 2
    _streamSubscription = uriLinkStream.listen((Uri? uri) {
      if (!mounted) {
        return;
      }
      debugPrint('Received URI: $uri');
      setState(() {
        _currentURI = uri;
        _err = null;
      });
      // 3
    }, onError: (Object err) {
      if (!mounted) {
        return;
      }
      debugPrint('Error occurred: $err');
      setState(() {
        _currentURI = null;
        if (err is FormatException) {
          _err = err;
        } else {
          _err = null;
        }
      });
    });
  }
}*/

/*Future<void> _initURIHandler() async {
  // 1
  /*if (!_initialURILinkHandled) {
    _initialURILinkHandled = true;
    // 2
    Fluttertoast.showToast(
        msg: "Invoked _initURIHandler",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white);*/
    try {
      // 3
      final initialURI = await getInitialUri();
      // 4
      if (initialURI != null) {
        debugPrint("Initial URI received $initialURI");
        if (!mounted) {
          return;
        }
        setState(() {
          _initialURI = initialURI;
        });
      } else {
        debugPrint("Null Initial URI received");
      }
    } on PlatformException {
      // 5
      debugPrint("Failed to receive initial uri");
    } on FormatException catch (err) {
      // 6
      if (!mounted) {
        return;
      }
      debugPrint('Malformed Initial URI received');
      setState(() => _err = err);
    }
 // }
}*/
