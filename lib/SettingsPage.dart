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
  final serverAddressController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool connected = false;
  bool checkingConnection = false;

  @override
  void initState() {
    super.initState();
    serverAddressController.text = getUriFullPath(serverURI);
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
                    const ElevatedButton(
                        onPressed: ExitApp, child: Text("Exit")),
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
                      getConnectionIcon()
                    ]),
                    ElevatedButton(
                        child: const Text('Save and close'),
                        onPressed: () {
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
    if (checkingConnection) return;
    var serverURItemp = parseURL(serverAddressController.text);

    if (serverURItemp == null) {
      toast("URL parsing error", context);
      return;
    }

    if (serverURItemp.scheme.isEmpty) {
      serverURItemp = setUriProperty(serverURItemp, scheme: "http");
    }
    checkingConnection = true;
    setState(() {});
    bool res = await checkConnection(serverURItemp);
    if (!res) {
      setState(() {});
      toast("Couldn't connect to the server", context);
      return;
    }
    serverURI = serverURItemp;
    settings.setString("httpScheme", serverURI.scheme);
    settings.setString("host", serverURI.host);
    settings.setInt("port", serverURI.port);
    RestartWidget.restartApp(context);
    Navigator.pop(context, true);
  }

  Future<bool> checkConnection(Uri uri) async {
    checkingConnection = true;

    var uriHealthz;

    if (uri.port != 0 && uri.port != 80) {
      uriHealthz = Uri(
          scheme: uri.scheme, host: uri.host, port: uri.port, path: "healthz");
    } else {
      uriHealthz = Uri(scheme: uri.scheme, host: uri.host, path: "healthz");
    }
    http.Response response;
    try {
      response = await httpClient.get(uriHealthz);
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
    var serverURItemp = parseURL(serverAddressController.text);

    if (serverURItemp == null) {
      return false;
    }

    if (serverURItemp.scheme.isEmpty) {
      setUriProperty(serverURItemp, scheme: "http");
    }

    bool res = await checkConnection(serverURItemp);
    setState(() {});
    return res;
  }

  Widget getConnectionIcon() {
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
