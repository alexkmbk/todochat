import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'HttpClient.dart';
import 'customWidgets.dart';
import 'todochat.dart';
import 'utils.dart';

class SettingsPage extends StatefulWidget {
  final bool restartAppOnChange;
  const SettingsPage({Key? key, required this.restartAppOnChange})
      : super(key: key);

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
    serverAddressController.text = serverURI.getFullPath();
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
      appBar: AppBar(
        shape: const Border(bottom: BorderSide(color: Colors.grey, width: 3)),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: appBarColor,
        actions: const [TextButton(onPressed: ExitApp, child: Text("Exit"))],
        title: const Text("SETTINGS",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 24,
            )),
      ),
      backgroundColor: Colors.white,
      body: Form(
          onWillPop: () async => false,
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                getTextField(
                  border: const UnderlineInputBorder(),
                  width: 300,
                  onFieldSubmitted: (value) {
                    checkingConnection = true;
                    setState(() {});
                    checkConnectionAndUpdateState();
                  },
                  controller: serverAddressController,
                  textAlign: TextAlign.center,
                  hintText: 'Server address',
                  validator: (value) => validateEmpty(value, 'Server address'),
                ),
                getConnectionIcon(),
              ]),
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
                                    'Save and close',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  onPressed: () {
                                    saveAndClose();
                                  }))),
                    )),
                Container(
                  height: 20,
                  color: closedTaskColor,
                )
              ])
            ],
          )),
    );
  }

  /*Future<void> openLoginPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }*/

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
    if (serverURI.getFullPath() != serverURItemp.getFullPath()) {
      serverURI = serverURItemp;
      settings.setString("httpScheme", serverURI.scheme);
      settings.setString("host", serverURI.host);
      settings.setInt("port", serverURI.port);
      if (widget.restartAppOnChange) {
        RestartWidget.restartApp(context);
      }
    }
    Navigator.pop(context, true);
  }

  Future<bool> checkConnection(Uri uri) async {
    checkingConnection = true;

    Uri uriHealthz;

    if (uri.port != 0 && uri.port != 80) {
      uriHealthz = Uri(
          scheme: uri.scheme, host: uri.host, port: uri.port, path: "healthz");
    } else if (uri.port == 0) {
      if (uri.scheme.isEmpty || uri.scheme == "http") {
        uriHealthz = Uri(
            scheme: uri.scheme.isEmpty ? "http" : uri.scheme,
            host: uri.host,
            port: 80,
            path: "healthz");
      } else {
        uriHealthz =
            Uri(scheme: uri.scheme, host: uri.host, port: 443, path: "healthz");
      }
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
    if (mounted) {
      setState(() {});
    }
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
    return const Icon(
      Icons.error,
      color: Colors.red,
    );
  }
}
