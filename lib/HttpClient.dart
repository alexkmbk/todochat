// ignore: file_names
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:todochat/utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

    final total = this.contentLength;
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
