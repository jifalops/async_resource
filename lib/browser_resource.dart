import 'dart:async';
import 'dart:html';
import 'package:meta/meta.dart';
import 'package:service_worker/worker.dart' as sw;
import 'package:async_resource/async_resource.dart';

export 'package:async_resource/async_resource.dart';

/// A network resource fetched and cached by a service worker in a browser
/// environment.
class ServiceWorkerResource<T> extends NetworkResource<T> {
  ServiceWorkerResource(
      {@required ServiceWorkerCacheEntry<T> cache,
      CacheStrategy strategy,
      Parser parser})
      : super(
            url: cache.url,
            cache: cache,
            maxAge: cache.maxAge,
            strategy: strategy,
            parser: parser);

  @override
  Future fetchContents() => sw.fetch(url);
}

/// The cache entry for a [url] in a service worker.
class ServiceWorkerCacheEntry<T> extends LocalResource<T> {
  ServiceWorkerCacheEntry(
      {@required this.name,
      @required String url,
      this.maxAge,
      this.binary: false,
      Parser<T> parser})
      : super(path: url, parser: parser);

  /// The name of the cache to use.
  final String name;
  final Duration maxAge;

  /// The data is either in bytes or a string.
  final bool binary;
  sw.Cache _cache;
  sw.Response _response;
  dynamic _responseContents;
  static const _modifiedKey = 'date';

  String get url => path;

  Future<sw.Cache> get cache async => _cache ??= await sw.caches.open(name);
  Future<sw.Response> get response async =>
      _response ??= await (await cache)?.match(url);

  @override
  Future<bool> get exists async => _isValid(await response);

  Future<bool> get isExpired async => hasExpired(await lastModified, maxAge);

  @override
  Future fetchContents() async => _getContents((await response)?.clone());

  Future _getContents(sw.Response resp) async =>
      binary ? (await resp?.arrayBuffer())?.asUint8List() : resp?.text();

  @override
  Future<DateTime> get lastModified async {
    final headers = (await response)?.headers;
    if (headers != null && headers.has(_modifiedKey)) {
      return DateTime.tryParse(headers[_modifiedKey]);
    }
    return null;
  }

  /// [contents] must be of type [sw.Response].
  @override
  Future<T> write(resp) async {
    assert(resp is sw.Response);
    _response = await resp
        ?.cloneWith(headers: {_modifiedKey: DateTime.now().toIso8601String()});
    _responseContents = await _getContents(resp);
    await (await cache)?.put(url, _response);
    return super.write(_response);
  }

  @override
  Future<void> delete() async {
    (await cache).delete(url);
    return super.delete();
  }

  @override
  preParseContents(contents) => contents is sw.Response
      // From network
      ? _responseContents
      // From disk
      : contents;
}

bool _isValid(sw.Response response) {
  if (response == null) return false;
  if (response.type == 'error') return false;
  return true;
}

/// A single entry in a [window.localStorage] or [window.sessionStorage] map.
class StorageEntry<T> extends LocalResource<T> {
  StorageEntry(this.key,
      {this.type: StorageType.localStorage,
      this.saveLastModified: false,
      Parser<T> parser})
      : super(path: type.name, parser: parser);

  final StorageType type;
  final String key;

  /// Create a duplicate storage entry when this entry is written.
  final bool saveLastModified;

  /// The storage key for modification time when [saveLastModified] is `true`.
  String get modifiedKey => '${key}_modified';

  Storage get storage => type == StorageType.localStorage
      ? window.localStorage
      : window.sessionStorage;

  String get value => storage[key];

  @override
  Future<bool> get exists async => storage.containsKey(key);

  @override
  Future fetchContents() async => value;

  @override
  Future<DateTime> get lastModified async =>
      saveLastModified ? DateTime.tryParse(storage[modifiedKey]) : null;

  @override
  Future<T> write(contents) async {
    storage[key] = contents;
    if (saveLastModified) {
      storage[modifiedKey] = DateTime.now().toIso8601String();
    }
    return super.write(contents);
  }

  @override
  Future<void> delete() async {
    storage.remove(key);
    if (saveLastModified) {
      storage.remove(modifiedKey);
    }
    return super.delete();
  }
}

/// See [window.localStorage] and [window.sessionStorage].
class StorageType {
  static const localStorage = StorageType._('localStorage');
  static const sessionStorage = StorageType._('sessionStorage');
  const StorageType._(this.name);
  final String name;
}
