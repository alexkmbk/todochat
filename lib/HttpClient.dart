// ignore: file_names
import 'package:http/http.dart' as http;

class HttpClient extends http.BaseClient {
  Map<String, String>? defaultHeaders;
  final http.Client _httpClient = http.Client();

  HttpClient({this.defaultHeaders}) : super();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (defaultHeaders != null) {
      request.headers.addAll(defaultHeaders!);
    }
    return _httpClient.send(request);
  }
}
