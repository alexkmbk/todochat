import 'dart:convert';
//import 'dart:html';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

class WSMessage {
  String command = "";
  dynamic data;
  WSMessage.fromJson(String json) {
    var map = jsonDecode(json);
    command = map["Command"];
    data = map["Data"];
  }
}

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
    io.exit(0);
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

String toBase64<T>(T data) {
  if (T == String) {
    return base64.encode(utf8.encode(data as String));
  } else {
    return base64.encode(data as List<int>);
  }
}

Uint8List? fromBase64(String str) {
  return base64Decode(str);
}

String left(String? str, int num) {
  if (str == null) return "";
  return str.substring(0, num);
}

//?param1=one&param2=two
String toUrlParams(Map<String, String> params) {
  String res = "";

  if (params.isNotEmpty) {
    res += "?";
    params.forEach((key, value) {
      res +=
          "${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}&";
    });
  }

  if (params.length > 1) {
    return left(res, res.length - 1);
  } else {
    return res;
  }
}

String getUriFullPath(Uri? uri) {
  if (uri == null) return "";

  String res = uri.scheme.isNotEmpty ? uri.scheme + "://" : "";
  res += uri.host;
  res += uri.port == 0 ? "" : uri.port.toString();
  res += "/" + uri.path;
  res += toUrlParams(uri.queryParameters);
  return res;
}

Uri setUriProperty(Uri uri,
    {String? scheme,
    String? host,
    int port = 0,
    String? path,
    Map<String, dynamic>? queryParameters}) {
  return Uri(
      scheme: scheme ?? uri.scheme,
      host: host ?? uri.host,
      port: port == 0 ? uri.port : port,
      path: path ?? uri.path,
      queryParameters: queryParameters ?? uri.queryParameters);
}

Uri? parseURL(String URL,
    {String? path, Map<String, String>? queryParameters}) {
  const String regex =
      r"^((?<scheme>[^:\/?#]+):(?=\/\/))?(\/\/)?(((?<login>[^:]+)(?::(?<password>[^@]+)?)?@)?(?<host>[^@\/?#:]*)(?::(?<port>\d+)?)?)?(?<path>[^?#]*)(\?(?<query>[^#]*))?(#(?<fragment>.*))?";

  RegExpMatch? match = RegExp(regex).firstMatch(URL);

  if (match != null) {
    return Uri(
      scheme: match.namedGroup("scheme"),
      host: match.namedGroup("host"),
      port: toInt(match.namedGroup("port")),
      query: match.namedGroup("query"),
      path: path,
      queryParameters: queryParameters,
    );
  }

  return null;
}

int toInt(String? str) {
  if (str == null || str.isEmpty)
    return 0;
  else
    return int.parse(str);
}

bool isImageFile(String? fileName) {
  if (fileName == null) return false;
  String? mimeStr = lookupMimeType(fileName);
  if (mimeStr != null) {
    var fileType = mimeStr.split('/');
    if (fileType.isNotEmpty) {
      return fileType[0] == "image";
    }
  }
  return false;
}

Future<Uint8List> readFile(String? path) async {
  if (path == null || path.isEmpty) return Uint8List(0);

  if (kIsWeb) {
    /*File file = File([], path);
    FileReader fileReader = FileReader();
    fileReader.readAsArrayBuffer(file);
    await fileReader.onLoad.first;
    var data = fileReader.result;*/
    return Uint8List(0);
  } else {
    io.File file = io.File(path);
    return await file.readAsBytes();
  }
}

Map<String, String> mapstr([String? key, String? value]) {
  if (key != null && value != null) {
    var res = <String, String>{};
    res[key] = value;
    return res;
  }
  return <String, String>{};
}
