// ignore: file_names
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:todochat/utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'todochat.dart';
import 'LoginPage.dart';
import 'customWidgets.dart';

import 'inifiniteTaskList.dart';
import 'utils.dart';
//import 'TaskMessagesPage.dart';
import 'MsgList.dart';
import 'package:provider/provider.dart';
import 'inifiniteTaskList.dart';

var connectWebSocketInProcess = false;
var isServerURI = true;

var httpClient = HttpClient();
WebSocketChannel? ws;
bool isWSConnected = false;
Stopwatch wsConnectionSince = Stopwatch()..start();

class HttpClient extends http.BaseClient {
  Map<String, String>? defaultHeaders;
  final http.Client _httpClient = http.Client();

  HttpClient({this.defaultHeaders}) : super();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (defaultHeaders != null) {
      request.headers.addAll(defaultHeaders!);
    }

    if (request.method == 'POST') {
      request.headers["Content-type"] = "application/json; charset=utf-8";
    }

    return _httpClient.send(request);
  }
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

class MultipartRequest extends http.MultipartRequest {
  /// Creates a new [MultipartRequest].
  MultipartRequest(
    String method,
    Uri url, {
    this.onProgress,
  }) : super(method, url);

  final void Function(int bytes, int totalBytes)? onProgress;

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// that will emit the request body.
  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final total = contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        if (onProgress != null) {
          onProgress!(bytes, total);
        }
        if (total >= bytes) {
          sink.add(data);
        }
      },
    );
    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}

Future<void> connectWebSocketChannel(Uri serverURI) async {
  /*if (wsConnectionSince.elapsedMilliseconds < 2000) {
    await Future.delayed(const Duration(seconds: 2));
  }*/
  if (ws != null) {
    ws!.sink.close();
    ws = null;
  }
  //Future.delayed(const Duration(seconds: 1)).then((value) {
  var scheme = serverURI.scheme == "http" ? "ws" : "wss";
  ws = WebSocketChannel.connect(
      setUriProperty(serverURI, scheme: scheme, path: "initMessagesWS"));
  wsConnectionSince = Stopwatch()..start();
  isWSConnected = true;
  /*if (ws != null) {
    ws!.sink.add(jsonEncode({"command": "init", "sessionID": sessionID}));
  }*/
  //listenWs();
  //ws!.sink.add(jsonEncode({"command": "init", "sessionID": sessionID}));
  //});

  /*ws = WebSocketChannel.connect(
          Uri.parse('ws://' + serverURI.authority + "/initMessagesWS"));*/
}

StreamSubscription? subscription;

void listenWs(TasksListProvider taskListProvider, BuildContext context) {
  final msgListProvider = Provider.of<MsgListProvider>(context, listen: false);

  if (sessionID.isNotEmpty && ws != null) {
    try {
      subscription = ws!.stream.listen((messageJson) {
        WSMessage wsMsg = WSMessage.fromJson(messageJson);
        if (wsMsg.command == "getMessages") {
          msgListProvider.addItems(wsMsg.data);
        } else if (wsMsg.command == "createMessage") {
          var message = Message.fromJson(wsMsg.data);
          final created = msgListProvider.addItem(message);
          taskListProvider.updateLastMessage(message.taskID, message, created);
        } else if (wsMsg.command == "deleteMessage") {
          var message = Message.fromJson(wsMsg.data);
          msgListProvider.deleteItem(message.ID);
        } else if (wsMsg.command == "createTask") {
          var task = Task.fromJson(wsMsg.data);
          taskListProvider.addItem(task);
        } else if (wsMsg.command == "deleteTask") {
          var taskID = wsMsg.data;
          taskListProvider.deleteItem(taskID, context);
        } else if (wsMsg.command == "updateTask") {
          var task = Task.fromJson(wsMsg.data);
          taskListProvider.updateItem(task);
        }
      }, onDone: () {
        isWSConnected = false;
        subscription!.cancel();
        /*checkLogin().then((value) async {
            if (value) {
//              subscription!.cancel();
              //connectWebSocketChannel(serverURI);
            } else {
              login().then((isLogin) async {
                if (isLogin) {
//                  subscription!.cancel();
                  //connectWebSocketChannel(serverURI);
                } else {
                  RestartWidget.restartApp();
                }
              });
            }
          }).onError((error, stackTrace) {
            RestartWidget.restartApp();
          });*/
      }, onError: (error) {
        if (kDebugMode) {
          print(error.toString());
        }
        RestartWidget.restartApp();
      });
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      Future.delayed(const Duration(seconds: 2))
          .then((value) => RestartWidget.restartApp());
    }
  }
}

Future<void> reconnect(
    TasksListProvider taskListProvider, BuildContext context) async {
  if (!connectWebSocketInProcess &&
      !isWSConnected &&
      isServerURI &&
      sessionID.isNotEmpty) {
    connectWebSocketInProcess = true;
    checkLogin().then((isLogin) {
      if (isLogin) {
        connectWebSocketChannel(serverURI).then((value) {
          connectWebSocketInProcess = false;
          listenWs(taskListProvider, context);
        });
      } else {
        login().then((isLogin) async {
          if (isLogin) {
            connectWebSocketChannel(serverURI).then((value) {
              connectWebSocketInProcess = false;
              listenWs(taskListProvider, context);
            });
          } else {
            RestartWidget.restartApp();
          }
        });
      }
    }).onError((error, stackTrace) {
      RestartWidget.restartApp();
    });
  }
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

/*String getUriFullPath(Uri? uri) {
  if (uri == null) return "";

  String res = uri.scheme.isNotEmpty ? "${uri.scheme}://" : "";
  res += uri.host;
  res += uri.port == 0 ? "" : ":${uri.port}";
  res += res.isNotEmpty && uri.path.isNotEmpty ? "/${uri.path}" : "";
  res += toUrlParams(uri.queryParameters);
  return res;
}*/

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

extension GetFullPath on Uri {
  String getFullPath() {
    String res = scheme.isNotEmpty ? "$scheme://" : "";
    res += host;
    res += port == 0 ? "" : ":$port";
    res += res.isNotEmpty && path.isNotEmpty ? "/$path" : "";
    res += toUrlParams(queryParameters);
    return res;
  }
}
