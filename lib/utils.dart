import 'dart:convert';
//import 'dart:html';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

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
  if (data == null) {
    return "";
  }
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

int toInt(String? str) {
  if (str == null || str.isEmpty) {
    return 0;
  } else {
    return int.parse(str);
  }
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

Future<String> saveInDownloads(Uint8List data, String FileName) async {
  return await FileSaver.instance.saveFile(FileName, data, extension(FileName));

  /*try {
    var downloadsDirectory = await DownloadsPathProvider.downloadsDirectory;
  } catch (e) {
    return "";
  }
  //File(FileName)writeAsBytes(data);*/
}

Future<bool> downloadAndOpenFile(String URL,
    {Map<String, String>? headers}) async {
  /*if (headers == null) {
    return await launch(URL);
  } else {
    return await launch(URL, headers: headers);
  }*/
  return false;
}

void OpenFileInApp(String? filePath) {
  if (filePath != null && filePath.isNotEmpty) {
    OpenFile.open(filePath);
  }
}

String getImageURLFromHTML(String html) {
  final regexp = RegExp(r'(?<=\bimg src=")[^"]*');
  final match = regexp.firstMatch(html);
  if (match != null) {
    final matchedText = match.group(0);
    return matchedText ?? "";
  }
  return "";
}

bool isWeb() {
  return kIsWeb;
}

extension SetCursorOnEnd on TextEditingController {
  void setCursorOnEnd() {
    selection = TextSelection.fromPosition(TextPosition(offset: text.length));
  }
}

String dateFormat(DateTime datetime, [String format = 'yyyy-MM-dd HH:mm']) {
  final DateFormat formatter = DateFormat(format);
  return formatter.format(datetime);
}
/*Map<String, HighlightedWord> getHighlightedWords(String? str) {
  Map<String, HighlightedWord> res = {};
  if (str == null) {
    return res;
  }
  var words = str.split(' ');
  words.forEach((word) {
    res[word] = HighlightedWord(
        onTap: () {}, textStyle: const TextStyle(color: Colors.green));
  });

  return res;
}*/
