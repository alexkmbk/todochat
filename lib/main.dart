import 'dart:async';
import 'package:flutter/material.dart';
import 'package:todochat/tasklist_provider.dart';
import 'HttpClient.dart';
import 'LoginPage.dart';
import 'ProjectsList.dart';
import 'SettingsPage.dart';
import 'customWidgets.dart';
import 'msglist_provider.dart';
import 'TasksPage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'todochat.dart';

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
    // final w = View.of(context).physicalGeometry.width *
    //     View.of(context).devicePixelRatio;
    var instance = WidgetsBinding.instance;
    var mediaQueryData = MediaQueryData.fromView(instance.window);
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
          value: TaskListProvider(),
        ),
      ],
      child: MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          title: 'ToDo Chat',
          theme: ThemeData(
            cardColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            textTheme: Theme.of(context).textTheme.apply(
                  fontSizeFactor: 1.0,
                  fontSizeDelta: 2.0,
                ),
            scaffoldBackgroundColor: Colors.grey[100],
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const MyHomePage(
            title: "ToDo Chat",
          )),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  //MsgListProvider msgListProvider;
  //TaskListProvider TaskListProvider;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //late TaskListProvider _TaskListProvider;

  @override
  void initState() {
    super.initState();
    //msgListProvider = Provider.of<MsgListProvider>(context, listen: false);
    //_TaskListProvider = Provider.of<TaskListProvider>(context, listen: false);

    //Login(_TaskListProvider);
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
                        colors: [Colors.white, Colors.white],
                        /*colors: [
                          Color.fromARGB(
                              255, 87, 108, 245), //Color(0xFF3366FF),
                          Color.fromARGB(
                              255, 109, 164, 246), //Color(0xFF00CCFF),
                        ],*/
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
                          /*RichText(
                              text: TextSpan(children: [
                            TextSpan(
                              text: "ToDo\n",
                              style: GoogleFonts.righteous(
                                  fontSize: 56, color: Colors.green),
                            ),
                            TextSpan(
                              text: "Chat",
                              style: GoogleFonts.righteous(
                                  height: 1.0,
                                  fontSize: 56,
                                  color: Colors.orangeAccent),
                              //00116d
                              //1a6ce3
                              /*TextStyle(
                                height: 1.0,
                                color: Colors.orangeAccent,
                                fontSize: 50,
                                fontWeight: FontWeight.bold)*/
                            ),
                          ])),*/
                          Image.asset(
                            "assets/images/todochat_logo.png",
                            width: 200,
                          ),
                          // TextInCircle(
                          //   width: 200,
                          //   color: Colors.white,
                          //   borderColor: Colors.green,
                          //   textWidget: TextSpan(
                          //     children: [
                          //       TextSpan(
                          //         text: "ToDo\n",
                          //         style: GoogleFonts.righteous(
                          //             fontSize: 56, color: Colors.green),
                          //       ),
                          //       TextSpan(
                          //         text: "Chat",
                          //         style: GoogleFonts.righteous(
                          //             height: 1.0,
                          //             fontSize: 56,
                          //             color: Colors.orangeAccent),
                          //         //00116d
                          //         //1a6ce3
                          //         /*TextStyle(
                          //       height: 1.0,
                          //       color: Colors.orangeAccent,
                          //       fontSize: 50,
                          //       fontWeight: FontWeight.bold)*/
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          const Spacer(),
                          if (snapshot.hasError)
                            IconButton(
                                iconSize: 40,
                                padding: const EdgeInsets.all(0.0),
                                onPressed: () => setState(() {}),
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Color.fromARGB(255, 203, 202, 202),
                                )),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Text('Connecting...',
                                style: TextStyle(
                                    color: Color.fromARGB(255, 203, 202, 202)),
                                textDirection: TextDirection.ltr),
                          const Spacer(),
                          SizedBox(
                              width: 200,
                              height: 50,
                              child: ElevatedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 20, 125, 199),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                  ),
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
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
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
  }

  Future<bool> initApp(BuildContext context) async {
    if (appInitialized) return true;
    bool res;

    final tasklist = Provider.of<TaskListProvider>(context, listen: false);

    settings = await SharedPreferences.getInstance();

    var httpScheme = settings.getString("httpScheme");
    var host = settings.getString("host");
    var port = settings.getInt("port");
    tasklist.projectID = settings.getInt("projectID");

    tasklist.showClosed = settings.getBool("showCompleted") ?? true;

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
      if (tasklist.projectID == null || tasklist.projectID == 0) {
        tasklist.project = await requestFirstItem();
        if (tasklist.project != null) {
          tasklist.projectID = tasklist.project!.ID;
          await tasklist.requestTasks(context);
        }
      }

      if (tasklist.projectID != null && tasklist.project == null) {
        tasklist.project = await getProject(tasklist.projectID);
        tasklist.project ??= await requestFirstItem();
      }
      // if (tasklist.project != null) {
      //   tasklist.projectID = tasklist.project!.ID;
      //   await tasklist.requestTasks(context);
      // }

      connectWebSocketChannel(serverURI).then((value) {
        listenWs(tasklist, context);
      });
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      reconnect(tasklist, context);
    });

    appInitialized = true;

    return true;
  }
}
