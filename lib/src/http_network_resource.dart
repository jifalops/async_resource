import 'dart:async';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:async_resource/async_resource.dart';

/// A [NetworkResource] over HTTP.
class HttpNetworkResource<T> extends NetworkResource<T> {
  HttpNetworkResource(
      {@required String url,
      @required LocalResource<T> cache,
      Duration maxAge,
      this.client,
      this.headers,
      this.binary: false})
      : super(url: url, cache: cache, maxAge: maxAge);

  /// Optional. The [http.Client] to use, recommended if frequently hitting
  /// the same server. If not specified, [http.get()] will be used instead.
  final http.Client client;

  /// Optional. The HTTP headers to send with the request.
  final Map<String, String> headers;

  /// Whether the underlying data is binary or string-based.
  final bool binary;

  @override
  Future<dynamic> fetchContents() async {
    final response = await (client == null
        ? http.get(url, headers: headers)
        : client.get(url, headers: headers));
    return (response != null && response.statusCode == 200)
        ? (binary ? response.bodyBytes : response.body)
        : null;
  }
}
