import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void toast(String? msg, BuildContext context) {
  if (msg == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
  ));
}

String? validateEmpty(String? value, String FieldName) {
  if (value == null || value.isEmpty) {
    return 'Please enter $FieldName';
  }
  return null;
}

void ExitApp() {
  if (kIsWeb) {
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    // running on the web!
  } else {
    exit(0);
  }

  /*if (Platform.isAndroid) {
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  } else
    exit(0);*/
}

Future<bool?> confirmDimissDlg(String queryText, BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirm"),
        content: const Text("Are you sure you wish to delete this item?"),
        actions: <Widget>[
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("DELETE")),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("CANCEL"),
          ),
        ],
      );
    },
  );
}

String toBase64(String str) {
  return base64.encode(utf8.encode(str));
}

//?param1=one&param2=two
String toUrlParams(Map<String, String> params) {
  String res = "";
  if (params.isNotEmpty) {
    res += "?";
    params.forEach((key, value) {
      res += Uri.encodeQueryComponent(key) +
          "=" +
          Uri.encodeQueryComponent(value) +
          "&";
    });
  }

  return res;
}
