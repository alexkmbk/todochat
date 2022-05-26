import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'HttpClient.dart';
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
        backgroundColor: completedTaskColor,
        body: Center(
            child: Form(
                onWillPop: () async => false,
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    const Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                            onPressed: ExitApp, child: Text("Exit"))),
                    const SizedBox(
                      height: 5,
                    ),
                    const Text("Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                        )),
                    const Spacer(),
                    Expanded(
                        child: Row(children: [
                      const Spacer(),
                      SizedBox(
                          width: 300,
                          child: getTextField(
                            onFieldSubmitted: (value) {
                              checkingConnection = true;
                              setState(() {});
                              checkConnectionAndUpdateState();
                            },
                            controller: serverAddressController,
                            border: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black)),
                            textAlign: TextAlign.center,
                            hintText: 'Server address',
                            validator: (value) =>
                                validateEmpty(value, 'Server address'),
                          )),
                      getConnectionIcon(),
                      const Spacer(),
                    ])),
                    const Spacer(),
                    SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                            child: const Text(
                              'Save and close',
                              style: TextStyle(fontSize: 16),
                            ),
                            onPressed: () {
                              saveAndClose();
                            })),
                    const SizedBox(
                      height: 50,
                    )
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

    Uri uriHealthz;

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
      return const SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(strokeWidth: 2));
    } else if (connected) {
      return const Icon(
        Icons.check,
        color: Colors.green,
      );
    }
    return const Icon(Icons.error);
  }
}
