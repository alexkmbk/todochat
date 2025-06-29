import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:todochat/state/projects.dart';
import 'package:todochat/state/settings.dart';
import 'package:todochat/state/tasks.dart';
import 'HttpClient.dart';
import 'settings_page.dart';
import 'customWidgets.dart';
import 'state/msglist_provider.dart';
import 'TasksPage.dart';
import 'package:provider/provider.dart';

import 'todochat.dart';

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
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor:
                Color(0xff7bb4fc), //Color.fromARGB(255, 48, 141, 252),
            selectionHandleColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.white,
            colorScheme:
                ColorScheme.fromSeed(seedColor: Colors.blue), //  <-- dark color
            textTheme: ButtonTextTheme
                .primary, //  <-- this auto selects the right color
          ),
          cardColor: Colors.white,
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
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
          return TasksPage();
        } else {
          return FutureBuilder<bool>(
            future:
                provider.initApp(context), // function where you call your api
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              // AsyncSnapshot<Your object type>
              if (snapshot.data != null && snapshot.data as bool) {
                return TasksPage();
              } else {
                return Container(
                    decoration: const BoxDecoration(
                      gradient: const LinearGradient(
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
                            const Image(
                              image:
                                  AssetImage("assets/images/todochat_logo.png"),
                              width: 200,
                            ),
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
                                        backgroundColor:
                                            Color.fromARGB(255, 20, 125, 199),
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(15)))),
                                    onPressed: () async {
                                      final redraw =
                                          await openSettings(context);
                                      // await Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //       builder: (context) => SettingsPage(
                                      //             key: UniqueKey(),
                                      //             restartAppOnChange: true,
                                      //           )),
                                      // );
                                      if (redraw) setState(() {});
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
}
