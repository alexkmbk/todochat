import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'customWidgets.dart';
import 'main.dart';
import 'utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool registrationMode = false;
  final userNameController = TextEditingController(text: '');
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
        body: registrationMode
            ? showRegistrationPage()
            : showLoginPage()); /*Column(
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
        headers: {"content-type": "application/json; charset=utf-8"});

    if (response.statusCode == 200) {
      var data = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      sessionID = data["sessionID"];
      return true;
    }

    return false;
  }

  Widget showLoginPage() {
    return Scaffold(
        body: Form(
            onWillPop: () async => false,
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ElevatedButton(onPressed: ExitApp, child: Text("Exit")),
                GetTextField(
                  controller: userNameController,
                  hintText: 'User name',
                  validator: (value) => validateEmpty(value, 'User name'),
                ),
                GetTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        child: const Text("Registration"),
                        onPressed: () {
                          setState(() {
                            registrationMode = true;
                          });
                        })),
                ElevatedButton(
                    child: const Text('Login'),
                    onPressed: () async {
                      if (_formKey.currentState!.validate() &&
                          await login(
                              userName: userNameController.text,
                              password: passwordController.text)) {
                        Navigator.pop(context, true);
                      }
                    }),
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
            const ElevatedButton(onPressed: ExitApp, child: Text("Exit")),
            GetTextField(
              controller: userNameController,
              hintText: 'User name',
              validator: (value) => validateEmpty(value, 'User name'),
            ),
            GetTextField(
                controller: emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                showClearButton: true),
            GetTextField(
              controller: passwordController,
              hintText: 'Password',
              obscureText: true,
            ),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    child: const Text("login"),
                    onPressed: () {
                      setState(() {
                        registrationMode = false;
                      });
                    })),
            ElevatedButton(
              child: const Text('Registration'),
              onPressed: () async {
                if (_formKey.currentState!.validate() && await registration()) {
                  Navigator.pop(context, true);
                }
              },
            )
          ],
        ));
  }
}

Future<void> openLoginPage(BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
  );
}

Future<bool> login({String? userName = "", String? password = ""}) async {
  if (userName == null || userName.isEmpty) {
    const storage = FlutterSecureStorage();
    userName = await storage.read(key: "userName");
    password = await storage.read(key: "password");
  }

  if (userName == null || userName.isEmpty || password == null) {
    return false;
  }

  var bytes = utf8.encode(password); // data being hashed
  String passwordHash = sha256.convert(bytes).toString();

  var url = setUriProperty(serverURI, path: "login");

  http.Response response;
  try {
    response = await httpClient.post(url,
        headers: {"content-type": "application/json; charset=utf-8"},
        body: jsonEncode({"UserName": userName, "passwordHash": passwordHash}));
  } catch (e) {
    return Future.error(e.toString());
  }

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body) as Map<String, dynamic>;

    sessionID = data["SessionID"];
    currentUserID = data["UserID"];

    const storage = FlutterSecureStorage();
    await storage.write(key: "userName", value: userName);
    await storage.write(key: "password", value: password);

    return true;
    /*var itemCount = jsonResponse['totalItems'];
      print('Number of books about http: $itemCount.');
    } else {
      print('Request failed with status: ${response.statusCode}.');*/
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
