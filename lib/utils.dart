import 'dart:convert';
//import 'dart:html';
import 'dart:io' as io;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:file_saver/file_saver.dart';
//import 'package:open_file/open_file.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class WSMessage {
  String command = "";
  dynamic data;
  WSMessage.fromJson(String json) {
    var map = jsonDecode(json);
    command = map["Command"];
    data = map["Data"];
  }
}

void toast(String? msg, BuildContext context, [int duration = 4000]) {
  if (msg == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    duration: Duration(milliseconds: duration),
  ));
}

String? validateEmpty(String? value, String FieldName) {
  if (value == null || value.isEmpty) {
    return 'Please enter $FieldName';
  }
  return null;
}

class Platform {
  bool get isWindows => io.Platform.isWindows;
  bool get isAndroid => io.Platform.isAndroid;
  bool get isIOS => io.Platform.isIOS;
  bool get isWeb => kIsWeb;
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

Future<io.File> saveFile(List<int> data, String fullFileName) async {
  //final file = XFile(fullFileName);
  //return file.saveTo(fullFileName);

  return io.File(fullFileName).writeAsBytes(data);
}

Future<String> saveInDownloads(Uint8List data, String fileName) async {
  return await FileSaver.instance
      .saveFile(name: fileName, bytes: data, ext: path.extension(fileName));

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

DateTime formJsonToDate(String? jsonDateStr) {
  if (jsonDateStr == null) return DateTime.utc(0);

  DateTime res = DateTime.tryParse(jsonDateStr) ?? DateTime.utc(0);
  res = res.toLocal();
  return res;
}

String formDateToJsonUtc(DateTime? date) {
  DateTime utcDate;
  if (date == null) {
    utcDate = DateTime.utc(0);
  } else {
    utcDate = date.toUtc();
  }
  return utcDate.add(DateTime.now().timeZoneOffset).toIso8601String();
}

extension ListExtension<E> on List<E> {
  void addUnique(E element) {
    if (!contains(element)) {
      add(element);
    }
  }
}

Size calcTextSize(String text, BuildContext context, {TextStyle? style}) {
  // create a nice span
  final textSpan = TextSpan(
    text: text,
    style: style,
  );
// which we paint with the media's scaling in place please
  final tp = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context));
  tp.layout();
// and return the size of the text span we just drew
  return tp.size;
}
