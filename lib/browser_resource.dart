library async_resource;

import 'dart:async';
import 'package:meta/meta.dart';
import 'package:service_worker/worker.dart' as sw;
import 'package:async_resource/async_resource.dart';

/// A network resource fetched and cached by a service-worker in a browser
/// environment.
class ServiceWorkerResource<T> extends NetworkResource<T> {
  ServiceWorkerResource(
      {@required ServiceWorkerCacheEntry<T> cache, CacheStrategy strategy})
      : super(
            url: cache.url,
            cache: cache,
            maxAge: cache.maxAge,
            strategy: strategy);

  @override
  Future fetchContents() => sw.fetch(url);

  /// [contents] must be a [sw.Response].
  @override
  preParseContents(contents) {
    assert(contents is sw.Response);
    return contents.body;
  }
}

/// The cache entry for a [url] in a service worker.
class ServiceWorkerCacheEntry<T> extends LocalResource<T> {
  ServiceWorkerCacheEntry(
      {@required this.name, @required String url, this.maxAge, Parser parser})
      : super(path: url, parser: parser);

  /// The name of the cache to use.
  final String name;
  final Duration maxAge;
  sw.Cache _cache;
  sw.Response _response;

  String get url => location;

  Future<sw.Cache> get cache async => _cache ??= await sw.caches.open(name);
  Future<sw.Response> get response async =>
      _response ??= await (await cache)?.match(url);

  @override
  Future<bool> get exists async => _isValid(await response);

  Future<bool> get isExpired async => hasExpired(await lastModified, maxAge);

  @override
  Future fetchContents() async => (await response)?.clone()?.body;

  @override
  Future<DateTime> get lastModified async {
    final resp = await response;
    final headers = resp?.headers;
    if (headers != null && headers.has('date')) {
      try {
        return DateTime.parse(headers['date']);
      } catch (ignored) {}
    }
    return null;
  }

  /// [contents] must be of type [sw.Response].
  @override
  Future<void> write(resp) async {
    assert(resp is sw.Response);
    final r = resp?.clone();
    _response = r;
    (await cache)?.put(url, r);
  }
}

bool _isValid(sw.Response response) {
  if (response == null) return false;
  if (response.type == 'error') return false;
  return true;
}
