import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'customWidgets.dart';
import 'main.dart';
import 'utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool registrationMode = false;
  final serverAddressController = TextEditingController(text: server);

  final _formKey = GlobalKey<FormState>();
  bool connected = false;
  bool checkingConnection = false;

  @override
  void initState() {
    super.initState();

    checkConnectionAndUpdateState();
  }

  @override
  void dispose() {
    serverAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Scaffold(
            body: Form(
                onWillPop: () async => false,
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const ElevatedButton(onPressed: ExitApp, child: Text("Exit")),
                    Row(children: [
                      Expanded(
                          child: GetTextField(
                        onFieldSubmitted: (value) {
                          checkingConnection = true;
                          setState(() {});
                          checkConnectionAndUpdateState();
                        },
                        controller: serverAddressController,
                        hintText: 'Server address',
                        validator: (value) =>
                            validateEmpty(value, 'Server address'),
                      )),
                      GetConnectionIcon()
                    ]),
                    ElevatedButton(
                        child: const Text('Save and close'),
                        onPressed: checkingConnection
                            ? null
                            : () async {
                                saveAndClose();
                              }),
                  ],
                ))));
  }

  Future<void> openLoginPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  Future<void> saveAndClose() async {
    checkingConnection = true;
    setState(() {});
    bool res = await checkConnection();
    if (!res) {
      setState(() {});
      toast("Couldn't connect to the server", context);
      return;
    }
    server = serverAddressController.text;
    settings.setString("server", server);
    Navigator.pop(context, true);
  }

  Future<bool> checkConnection() async {
    checkingConnection = true;
    Uri url;
    try {
      url = Uri.http(serverAddressController.text, '/healthz');
    } catch (e) {
      connected = false;
      checkingConnection = false;
      return false;
    }

    http.Response response;
    try {
      response = await httpClient.get(url);
    } catch (e) {
      connected = false;
      checkingConnection = false;
      return false;
    }

    if (response.statusCode == 200) {
      checkingConnection = false;
      connected = true;
      return true;
    }
    checkingConnection = false;
    connected = false;
    return false;
  }

  Future<bool> checkConnectionAndUpdateState() async {
    bool res = await checkConnection();
    setState(() {});
    return res;
  }

  Widget GetConnectionIcon() {
    if (checkingConnection) {
      return const CircularProgressIndicator();
    } else if (connected) {
      return const Icon(
        Icons.check,
        color: Colors.green,
      );
    }
    return const Icon(Icons.error);
  }
}
