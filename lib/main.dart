import 'dart:async';
import 'package:flutter/material.dart';
import 'package:todochat/models/project.dart';
import 'package:todochat/projects_list.dart';
import 'package:todochat/state/projects.dart';
import 'package:todochat/state/settings.dart';
import 'package:todochat/state/tasks.dart';
import 'package:todochat/utils.dart';
import 'HttpClient.dart';
import 'LoginRegistrationPage.dart';
import 'settings_page.dart';
import 'customWidgets.dart';
import 'state/msglist_provider.dart';
import 'TasksPage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'todochat.dart';

Timer? timer;

void main() {
  runApp(AppLifecyclePage(child: MyApp()));
  // runApp(
  //   RestartWidget(
  //     builder: () {
  //       return MyApp();
  //     },
  //     beforeRestart: () {
  //       if (timer != null) {
  //         timer!.cancel();
  //       }
  //       appInitialized = false;
  //       sessionID = "";
  //       if (ws != null) {
  //         ws!.sink.close(1001);
  //         ws = null;
  //         httpClient.close();
  //         isWSConnected = false;

  //         ///final context = getGlobalContext();
  //         /*if (context != null) {
  //           Provider.of<MsgListProvider>(context, listen: false).dispose();
  //         }*/
  //       }
  //     },
  //   ),
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MsgListProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => TasksState(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProjectsState(),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsState(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        title: 'ToDo Chat',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.white,
            colorScheme:
                ColorScheme.fromSeed(seedColor: Colors.blue), //  <-- dark color
            textTheme: ButtonTextTheme
                .primary, //  <-- this auto selects the right color
          ),
          cardColor: Colors.white,
          dialogBackgroundColor: Colors.white,
          textTheme: Theme.of(context).textTheme.apply(
                fontSizeFactor: 1.0,
                fontSizeDelta: 2.0,
                //displayColor: Colors.grey,
              ),
          scaffoldBackgroundColor: Colors.grey[100],
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MyHomePage(
          title: "ToDo Chat",
        ),
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
  @override
  void initState() {
    super.initState();
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
    return Consumer<SettingsState>(
      builder: (context, provider, child) {
        if (appInitialized) {
          return const TasksPage();
        } else {
          return FutureBuilder<bool>(
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
                            if (snapshot.hasError &&
                                snapshot.connectionState !=
                                    ConnectionState.waiting)
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
                              const Text(
                                'Connecting...',
                                style: TextStyle(
                                    decoration: TextDecoration.none,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 203, 202, 202)),
                              ),
                            const Spacer(),
                            SizedBox(
                                width: 200,
                                height: 50,
                                child: ElevatedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 20, 125, 199),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                    ),
                                    onPressed: () async {
                                      final res = await openSettings(context,
                                          restartAppOnChange: true);
                                      // await Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //       builder: (context) => SettingsPage(
                                      //             key: UniqueKey(),
                                      //             restartAppOnChange: true,
                                      //           )),
                                      // );
                                      if (res) setState(() {});
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
            //),
          );
        }
      },
    );
  }

  Future<bool> initApp(BuildContext context) async {
    if (appInitialized) return true;

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
    }
    settings = await SharedPreferences.getInstance();

    var screenModeIndex =
        settings.getInt("ScreenMode") ?? ScreenModes.Auto.index;

    isDesktopMode = GetDesktopMode(ScreenModes.values[screenModeIndex]);

    var sessionID_ = settings.getString("sessionID");
    if (sessionID_ == null) {
      sessionID = "";
    } else
      sessionID = sessionID_;

    var httpScheme = settings.getString("httpScheme");
    var host = settings.getString("host");
    var port = settings.getInt("port");
    autoLogin = settings.getBool("autoLogin") ?? true;
    if (isWeb() && (host == null || host.isEmpty)) {
      host = Uri.base.host;
      port = Uri.base.port;
      httpScheme = Uri.base.scheme;
    }

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
    bool login = false;
    if (sessionID.isNotEmpty && autoLogin) {
      httpClient.defaultHeaders = {"sessionID": sessionID};
      try {
        login = await checkLogin();
      } catch (e) {
        return Future.error(e.toString());
      }
    }
    if (!login) {
      await openLoginPage(context);
    }

    final tasklist = context.read<TasksState>();

    if (isServerURI && sessionID.isNotEmpty) {
      connectWebSocketChannel(serverURI).then((value) {
        listenWs(tasklist, context);
      });
    }

    final projectID = settings.getInt("projectID") ?? 0;

    Project? currentProject;
    currentProject = (await getProject(projectID));
    if (currentProject == null || currentProject.isEmpty) {
      currentProject = await requestFirstItem();
    }

    tasklist.showClosed = settings.getBool("showCompleted") ?? true;
    tasklist.currentTaskID = settings.getInt("currentTaskID") ?? 0;
    tasklist.setCurrentProject(currentProject, context);

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      reconnect(tasklist, context);
    });

    appInitialized = true;

    return true;
  }
}
