import 'dart:convert';

import 'package:flutter/material.dart';
//import 'dart:io';

import 'package:http/http.dart' as http;
//import 'dart:convert' as convert;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:todochat/tasklist_provider.dart';

import 'HttpClient.dart';
import 'SettingsPage.dart';
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
  bool registrationMode = false;
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
    return Scaffold(
        appBar: AppBar(
          shape: const Border(bottom: BorderSide(color: Colors.grey, width: 3)),
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: appBarColor,
          actions: const [TextButton(onPressed: ExitApp, child: Text("Exit"))],
          title: const Text("LOGIN",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 24,
              )),
        ),
        backgroundColor: Colors.white,
        body: registrationMode
            ? showRegistrationPage()
            : showLoginPage(
                context)); /*Column(
      children: [
        ElevatedButton(onPressed: ExitApp, child: Text("Exit")),
        registrationMode ? showRegistrationPage() : showLoginPage()
      ],
    ));*/
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

      if (serverURI.scheme != "http" || !isWeb()) {
        const storage = FlutterSecureStorage();
        await storage.write(
            key: "userName", value: userNameController.text.trim());
        await storage.write(
            key: "password", value: passwordController.text.trim());
      }

      // final msgListProvider =
      //     Provider.of<MsgListProvider>(context, listen: false);

      final taskListProvider =
          Provider.of<TaskListProvider>(context, listen: false);
      taskListProvider.clear(context);
      await taskListProvider.requestTasks(context);
      //msgListProvider.refresh();

      return true;
    } else {
      toast(utf8.decode(response.bodyBytes), context);
    }

    return false;
  }

  Widget showLoginPage(BuildContext context) {
    return Scaffold(
        body: Form(
            onWillPop: () async => false,
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
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
                                showDialog(
                                    context: context,
                                    builder: (context) => SettingsPage(
                                          key: UniqueKey(),
                                          restartAppOnChange: true,
                                        ));
                                /*MaterialPageRoute(
                              builder: (context) => const SettingsPage());*/
                              }),
                          TextButton(
                              child: const Text("Registration"),
                              onPressed: () {
                                setState(() {
                                  registrationMode = true;
                                });
                              })
                        ])),
                const Spacer(),
                Column(children: [
                  SizedBox(
                      height: 80,
                      child: Container(
                        color: closedTaskColor,
                        child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                                width: 200,
                                height: 50,
                                child: ElevatedButton(
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
                                    }))),
                      )),
                  Container(
                    height: 20,
                    color: closedTaskColor,
                  )
                ]),
              ],
            )));
  }

  Widget showRegistrationPage() {
    return Form(
        onWillPop: () async => false,
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
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
                          setState(() {
                            registrationMode = false;
                          });
                        }))),
            const Spacer(),
            Column(children: [
              SizedBox(
                  height: 80,
                  child: Container(
                    color: closedTaskColor,
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                            width: 200,
                            height: 50,
                            child: ElevatedButton(
                              child: const Text(
                                'Registration',
                                style: TextStyle(fontSize: 16),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate() &&
                                    await registration()) {
                                  isLoginPageOpen = false;
                                  Navigator.pop(context, true);
                                }
                              },
                            ))),
                  )),
              Container(
                height: 20,
                color: closedTaskColor,
              )
            ]),
          ],
        ));
  }
}

Future<void> openLoginPage(BuildContext context) async {
  if (isLoginPageOpen) {
    return;
  }
  isLoginPageOpen = true;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
  );
}

Future<bool> login(
    {String? userName = "",
    String? password = "",
    BuildContext? context}) async {
  if (userName == null || userName.isEmpty) {
    if (serverURI.scheme != "http" || !isWeb()) {
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
    response = await httpClient.post(setUriProperty(serverURI, path: "login"),
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

    if (serverURI.scheme != "http" || !isWeb()) {
      const storage = FlutterSecureStorage();
      await storage.write(key: "userName", value: userName);
      await storage.write(key: "password", value: password);
    }

    if (userChanged && context != null) {
      // final msgListProvider =
      //     Provider.of<MsgListProvider>(context, listen: false);

      final taskListProvider =
          Provider.of<TaskListProvider>(context, listen: false);
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

Future<bool> checkLogin() async {
  http.Response response;
  try {
    response =
        await httpClient.get(setUriProperty(serverURI, path: "checkLogin"));
  } catch (e) {
    return Future.error(e.toString());
  }

  if (response.statusCode == 200) {
    return true;
  }

  return false;
}
