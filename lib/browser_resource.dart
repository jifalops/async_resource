import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'package:service_worker/worker.dart' as sw;
import 'package:async_resource/async_resource.dart';

/// Represents storage options for a browser.
class SwBrowserResource<T> extends LocalResource<T> {
  SwBrowserResource(this.name, String url, {Parser<T> parse})
      : super(path: url, parse: parse);

  final String name;
  sw.Cache _cache;

  Future<sw.Cache> get cache async => _cache ??= await sw.caches.open(name);
  Future<sw.Response> get contentResponse async => (await cache).match(path);
  Future<sw.Response> get modTimeResponse async =>
      (await cache).match(path + '/modTime');

  @override
  Future<bool> get exists async => (await contentResponse).ok;

  @override
  Future fetchContents() async => (await contentResponse).body;

  @override
  Future<DateTime> get lastModified async {
    final modTime = await modTimeResponse;
    return modTime.ok ? DateTime.parse(modTime.body) : null;
  }

  @override
  Future<void> write(contents) async {
    final c = await cache;
    c.put(path, sw.Response(contents));
    c.put(path + '/modTime', sw.Response(DateTime.now()));
  }
}
