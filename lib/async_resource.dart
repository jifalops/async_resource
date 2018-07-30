library async_resource;

import 'dart:async';
import 'package:path/path.dart';
import 'package:meta/meta.dart';

export 'src/http_network_resource.dart';

/// [contents] will either be a [String] or [List<int>], depending on whether
/// the underlying resource is binary or string based.
typedef T Parser<T>(dynamic contents);

/// An [AsyncResource] represents data from the network or disk such as a native
/// I/O File, browser service-worker cache, or browser local storage.
abstract class AsyncResource<T> {
  AsyncResource({this.parse});

  // final Fetcher fetch;
  final Parser<T> parse;
  T _data;

  /// Synchronously get the most recently loaded data.
  T get data => _data;

  /// Gets the most readily available data or refreshes it if [forceReload] is
  /// `true`.
  Future<T> get({bool forceReload: false}) async {
    if (_data == null || forceReload) {
      final contents = await fetchContents();
      _data = parse == null ? contents : parse(contents);
    }
    return _data;
  }

  /// Fetch the raw contents from the underlying platform.
  ///
  /// Returns a [String] or [List<int>], depending on whether the underlying
  /// resource is binary or string based.
  Future<dynamic> fetchContents();
}

/// A local resources such as a native file or browser cache.
abstract class LocalResource<T> extends AsyncResource<T> {
  LocalResource({@required this.path, Parser<T> parse}) : super(parse: parse);

  /// The location of this resource.
  final String path;

  /// The [basename()] of the [path].
  String get name => basename(path);

  /// Persist the contents to disk.
  Future<void> write(dynamic contents);
  Future<bool> get exists;

  /// Returns `null` if [exists()] is `false`.
  Future<DateTime> get lastModified;
}

/// Network resources are fetched from the network and will cache a local copy.
///
/// Its [Parser] is defined by the [cache] [LocalResource].
abstract class NetworkResource<T> extends AsyncResource<T> {
  NetworkResource({@required this.url, @required this.cache, this.maxAge})
      : super(parse: cache.parse);

  /// The location of the data to fetch and cache.
  final String url;

  /// The local copy of the data fetched from [url].
  final LocalResource<T> cache;

  /// Determines when the [cache] copy has expired and should be refetched.
  final Duration maxAge;

  /// Returns `true` if [cache] does not exist, `false` if it exists but
  /// [maxAge] is null; otherwise compares the [cache]'s age to [maxAge].
  Future<bool> get isExpired async {
    final modTime = await cache.lastModified;
    return modTime == null
        ? true
        : (maxAge == null
            ? false
            : new DateTime.now().difference(modTime) > maxAge);
  }

  /// Retrieve the most readily available data in the order of RAM, cache,
  /// then network. If [forceReload] is `true` then this will fetch from the
  /// network, using the cache as a fallback if the network request fails unless
  /// [allowCacheFallback] is `false`.
  @override
  Future<T> get(
      {bool forceReload: false, bool allowCacheFallback = true}) async {
    if (_data != null && !forceReload) {
      return _data;
    } else if (forceReload || await isExpired) {
      print('${cache.name}: Fetching from $url');
      final contents = await fetchContents();
      if (contents != null) {
        print('$url Fetched. Updating cache...');
        cache.write(contents);
        return _data = parse(contents);
      } else {
        if (allowCacheFallback) {
          print('$url Using a cached copy if available.');
          return cache.get();
        } else {
          print('Not attempting to find in cache.');
          return null;
        }
      }
    } else {
      print('Loading cached copy of ${cache.name}');
      return _data = await cache.get();
    }
  }
}
