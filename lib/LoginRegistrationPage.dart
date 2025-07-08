import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
//import 'dart:io';

import 'package:http/http.dart' as http;
//import 'dart:convert' as convert;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:todochat/models/project.dart';
import 'package:todochat/state/tasks.dart';

import 'HttpClient.dart';
import 'settings_page.dart';
import 'customWidgets.dart';
import 'todochat.dart';
import 'utils.dart';

//import 'dart:html' as html;

bool isLoginPageOpen = false;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userNameController = TextEditingController(text: currentUserName);
  final emailController = TextEditingController(text: '');
  final passwordController = TextEditingController(text: '');

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    emailController.addListener(() {
      setState(() {});
    });
    passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Row(children: [
          Text("Login"),
          Spacer(),
          TextButton(onPressed: ExitApp, child: Text("Exit")),
        ]),
        titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        //backgroundColor: Color(ColorResources.BLACK_ALPHA_65),
        content: Form(
          canPop: false,
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 300,
                  child: TextFieldEx(
                    autofillHints: [AutofillHints.username],
                    controller: userNameController,
                    border: const UnderlineInputBorder(),
                    hintText: 'User name',
                    validator: (value) => validateEmpty(value, 'User name'),
                    onFieldSubmitted: (value) {
                      //FocusScope.of(context).nextFocus();
                    },
                  )),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                  width: 300,
                  child: TextFieldEx(
                      autofillHints: [AutofillHints.password],
                      controller: passwordController,
                      border: const UnderlineInputBorder(),
                      hintText: 'Password',
                      obscureText: true,
                      //textInputAction: TextInputAction.send,
                      onFieldSubmitted: (value) async {
                        if (_formKey.currentState!.validate() &&
                            await login(
                                userName: userNameController.text,
                                password: value,
                                context: context)) {
                          isLoginPageOpen = false;
                          Navigator.pop(context, true);
                        }
                      })),
              SizedBox(
                  width: 300,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                            child: const Text("Settings"),
                            onPressed: () {
                              openSettings(context);
                            }),
                        TextButton(
                            child: const Text("Registration"),
                            onPressed: () {
                              openRegistrationPage(context).then((value) {
                                Navigator.pop(context, value);
                              });
                            })
                      ])),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    await login(
                        userName: userNameController.text,
                        password: passwordController.text,
                        context: context)) {
                  isLoginPageOpen = false;
                  Navigator.pop(context, true);
                }
              })
        ],
      ),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPagePageState();
}

class _RegistrationPagePageState extends State<RegistrationPage> {
  final userNameController = TextEditingController(text: currentUserName);
  final emailController = TextEditingController(text: '');
  final passwordController = TextEditingController(text: '');

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    emailController.addListener(() {
      setState(() {});
    });
    passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Row(children: [
          Text("Registration"),
          Spacer(),
          TextButton(onPressed: ExitApp, child: Text("Exit")),
        ]),
        titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        //backgroundColor: Color(ColorResources.BLACK_ALPHA_65),
        content: Form(
          canPop: false,
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFieldEx(
                controller: userNameController,
                hintText: 'User name',
                border: const UnderlineInputBorder(),
                width: isDesktopMode ? 300 : null,
                validator: (value) => validateEmpty(value, 'User name'),
                onFieldSubmitted: (value) {
                  FocusScope.of(context).nextFocus();
                },
              ),
              const SizedBox(
                height: 20,
              ),
              TextFieldEx(
                controller: emailController,
                hintText: 'Email',
                border: const UnderlineInputBorder(),
                width: isDesktopMode ? 300 : null,
                keyboardType: TextInputType.emailAddress,
                showClearButton: true,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).nextFocus();
                },
              ),
              const SizedBox(
                height: 20,
              ),
              TextFieldEx(
                controller: passwordController,
                hintText: 'Password',
                border: const UnderlineInputBorder(),
                width: isDesktopMode ? 300 : null,
                obscureText: true,
              ),
              SizedBox(
                  width: isDesktopMode ? 300 : null,
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          child: const Text("login"),
                          onPressed: () {
                            Navigator.pop(context, false);
                            openLoginPage(context);
                          }))),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            child: const Text(
              'Registration',
              style: TextStyle(fontSize: 16),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate() && await registration()) {
                isLoginPageOpen = false;
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool> registration() async {
    var bytes =
        utf8.encode(passwordController.text.trim()); // data being hashed
    String passwordHash = sha256.convert(bytes).toString();

    var response = await httpClient.post(
      Uri.http(serverURI.authority, '/registerNewUser'),
      body: jsonEncode({
        "Name": userNameController.text.trim(),
        "passwordHash": passwordHash
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      sessionID = data["sessionID"];
      currentUserID = data["userID"];
      currentUserName = userNameController.text.trim();
      httpClient.defaultHeaders = {"sessionID": sessionID};

      settings.setString("sessionID", sessionID);
      if (!isWeb()) {
        const storage = FlutterSecureStorage();
        await storage.write(
            key: "userName", value: userNameController.text.trim());
        await storage.write(
            key: "password", value: passwordController.text.trim());
      }

      // final msgListProvider =
      //     Provider.of<MsgListProvider>(context, listen: false);

      final taskListProvider = Provider.of<TasksState>(context, listen: false);
      taskListProvider.clear(context);
      await taskListProvider.requestTasks(context);
      //msgListProvider.refresh();

      return true;
    } else {
      toast(utf8.decode(response.bodyBytes), context);
    }

    return false;
  }
}

// Future<bool> showLoginPage(BuildContext context) async {
//   switch (await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return LoginPage();
//       })) {
//     case true:
//       return true;
//     case false:
//     case null:
//       return false;
//   }
//   return false;
// }

Future<bool> openRegistrationPage(BuildContext context) async {
  switch (await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          body: RegistrationPage(),
          backgroundColor: Colors.transparent,
        );
      })) {
    case true:
      return true;
    case false:
    case null:
      return false;
  }
  return false;
}

Future<bool> openLoginPage(BuildContext context) async {
  switch (await showDialog<bool>(
    context: context,
    builder: (context) => ScaffoldMessenger(
      child: Builder(
        builder: (context) => Scaffold(
          body: LoginPage(),
          backgroundColor: Colors.transparent,
        ),
      ),
    ),
  )) {
    case true:
      return true;
    case false:
    case null:
      return false;
  }
  return false;
}

Future<bool> login(
    {String? userName = "",
    String? password = "",
    BuildContext? context,
    Project? project,
    Map? unreadMessagesByProjects}) async {
  if (userName == null || userName.isEmpty) {
    if (!isWeb()) {
      const storage = FlutterSecureStorage();
      userName = await storage.read(key: "userName");
      password = await storage.read(key: "password");
    }
  }

  /*if (isWeb()) {
    var credentials = html.window.navigator.credentials;

    if (credentials != null) {
      html.Credential credential = await credentials.get({password: true});
      userName = credential.id;
      password = credential.type;
    }
  }*/
  if (userName == null || userName.isEmpty || password == null) {
    return false;
  }

  var bytes = utf8.encode(password); // data being hashed
  String passwordHash = sha256.convert(bytes).toString();

  http.Response response;
  try {
    final params = {
      'getProject': (project != null).toString(),
      'returnUnreadMessages': (unreadMessagesByProjects != null).toString()
    };
    response = await httpClient.post(
        setUriProperty(serverURI, path: "login", queryParameters: params),
        body: jsonEncode({"UserName": userName, "passwordHash": passwordHash}));
  } catch (e) {
    return Future.error(e.toString());
  }

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);

    sessionID = data["SessionID"];

    final userChanged = (currentUserID != data["UserID"]);
    currentUserID = data["UserID"];
    currentUserName = userName;
    httpClient.defaultHeaders = {"sessionID": sessionID};

    if (project != null) {
      var project_ = Project.fromJson(data["project"]);
      project.ID = project_.ID;
      project.Description = project_.Description;
    }

    unreadMessagesByProjects =
        data["UnreadMessagesByProjects"] as Map<Project, int>?;

    settings.setString("sessionID", sessionID);

    if (!isWeb()) {
      const storage = FlutterSecureStorage();
      await storage.write(key: "userName", value: userName);
      await storage.write(key: "password", value: password);
    }

    if (userChanged && context != null) {
      // final msgListProvider =
      //     Provider.of<MsgListProvider>(context, listen: false);

      final taskListProvider = Provider.of<TasksState>(context, listen: false);
      taskListProvider.clear(context);
      taskListProvider.requestTasks(context);
      //if (isDesktopMode) {
      //msgListProvider.refresh();
      //}
    }

    return true;
    /*var itemCount = jsonResponse['totalItems'];
      print('Number of books about http: $itemCount.');
    } else {
      print('Request failed with status: ${response.statusCode}.');*/
  } else if (response.statusCode == 404) {
    if (context != null) {
      toast("Couldn't connect to the server", context);
    }
  } else if (response.statusCode == 401) {
    if (context != null) {
      toast("Wrong password or user name.", context);
    }
  }
  /*var client = HttpClient();
    try {
      HttpClientRequest request = await client.get(server, 80, '/login');
      request.headers.add("UserName", userNameController.text);
      request.headers.add("passwordHash", passwordHash);
      HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        /*var data = jsonDecode(response.body);
      sessionID = data.sessionID;*/
        final stringData = await response.transform(utf8.decoder).join();
        var data = jsonDecode(stringData);
        sessionID = data["sessionID"];
        client.close();
        return true;
      }
    } finally {
      client.close();
    }*/
  return false;
}

Future<bool> checkLogin(
    {Project? project, Map? unreadMessagesByProjects}) async {
  http.Response response;
  try {
    response = await httpClient
        .get(setUriProperty(serverURI, path: "checkLogin", queryParameters: {
      'getProject': (project != null).toString(),
      'returnUnreadMessages': (unreadMessagesByProjects != null).toString()
    }));
  } catch (e) {
    return Future.error(e.toString());
  }

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    try {
      currentUserName = data["username"];
      currentUserID = data["userid"];
      if (project != null) {
        var project_ = Project.fromJson(data["project"]);
        project.ID = project_.ID;
        project.Description = project_.Description;
      }
      unreadMessagesByProjects = data["unreadMessagesByProjects"];
    } catch (e) {}
    return true;
  }

  return false;
}

Future<bool> logoff() async {
  http.Response response;
  try {
    response = await httpClient.get(setUriProperty(serverURI, path: "logoff"));
  } catch (e) {
    return Future.error(e.toString());
  }

  if (response.statusCode == 200) {
    return true;
  }

  return false;
}
