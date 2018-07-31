import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'package:service_worker/worker.dart' as sw;
import 'package:async_resource/async_resource.dart';

/// Represents storage options for a browser.
class SwBrowserResource<T> extends LocalResource<T> {
  SwBrowserResource(String path, {Parser<T> parse})
      : request = sw.Request(path),
        super(path: path, parse: parse);

  final sw.Request request;

  // TODO: implement exists
  @override
  Future<bool> get exists =>
      sw.caches.open(path).then((cache) => cache.put(path, sw.Response('')));

  @override
  Future fetchContents() {
    // TODO: implement fetchContents
  }

  // TODO: implement lastModified
  @override
  Future<DateTime> get lastModified => null;

  @override
  Future<void> write(contents) {
    // TODO: implement write
  }
}
