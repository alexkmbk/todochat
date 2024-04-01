import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'HttpClient.dart';
import 'customWidgets.dart';
import 'todochat.dart';
import 'utils.dart';

Future<bool> openSettings(BuildContext context,
    {bool restartAppOnChange = true}) async {
  switch (await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return SettingsPage(restartAppOnChange: restartAppOnChange);
      })) {
    case true:
      return true;
    case false:
    case null:
      return false;
  }
  return false;
}

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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      // child: Scaffold(
      //   appBar: AppBar(
      //     shape: const Border(bottom: BorderSide(color: Colors.grey, width: 3)),
      //     automaticallyImplyLeading: false,
      //     elevation: 0,
      //     backgroundColor: appBarColor,
      //     actions: const [TextButton(onPressed: ExitApp, child: Text("Exit"))],
      //     title: const Text("SETTINGS",
      //         style: TextStyle(
      //           color: Colors.grey,
      //           fontSize: 24,
      //         )),
      //   ),
      //   backgroundColor: Colors.white,
      //   body:
      child: AlertDialog(
        title: Row(children: [
          Text("Settings"),
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
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TextFieldEx(
                        labelText: "Server address",
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
                        validator: (value) =>
                            validateEmpty(value, 'Server address'),
                        choiceList: settings.getStringList("addresses")),
                    getConnectionIcon(),
                  ]),
                ])),
        actions: [
          TextButton(
            child: const Text(
              'OK',
              style: TextStyle(fontSize: 16),
            ),
            onPressed: () {
              saveAndClose();
            },
            // style: OutlinedButton.styleFrom(
            //   backgroundColor:
            //       const Color.fromARGB(255, 20, 125, 199),
            //   shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(15)),
            // ),
          ),
        ],
      ),
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

    if (serverURI.getFullPath().isNotEmpty) {
      var addresses = settings.getStringList("addresses");
      if (addresses == null) {
        addresses = new List.empty(growable: true);
      }
      addresses.addUnique(serverURI.getFullPath());
      settings.setStringList("addresses", addresses);
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
