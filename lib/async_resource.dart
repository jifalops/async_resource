library async_resource;

import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

export 'src/http_network_resource.dart';

/// [contents] will either be a [String] or [List<int>], depending on whether
/// the underlying resource is binary or string based.
typedef T Parser<T>(dynamic contents);

/// An [AsyncResource] represents data from the network or disk such as a native
/// I/O File, browser service-worker cache, or browser local storage.
abstract class AsyncResource<T> {
  AsyncResource({@required this.location});

  /// The location (a path or url) of the resource.
  final String location;

  /// Synchronously get the most recently loaded data.
  T get data;

  /// Gets the most readily available data or refreshes it if [forceReload] is
  /// `true`.
  Future<T> get({bool forceReload: false});

  /// Fetch the raw contents from the underlying platform.
  ///
  /// Returns a [String] or [List<int>], depending on whether the underlying
  /// resource is binary or string based.
  Future<dynamic> fetchContents();

  Future<dynamic> _tryFetchContents() async {
    try {
      return await fetchContents();
    } catch (ignored) {}
  }
}

/// A local resources such as a native file or browser cache.
abstract class LocalResource<T> extends AsyncResource<T> {
  LocalResource({@required String path, this.parser}) : super(location: path);

  @override
  T get data => _data;
  T _data;

  final Parser<T> parser;

  /// Allows [NetworkResource] to define the parser, which is more natural to
  /// use.
  Parser<T> _parserOverride;

  @override
  Future<T> get({bool forceReload: false}) async {
    if (_data == null || forceReload) {
      _update(await _tryFetchContents());
    }
    return _data;
  }

  /// [contents] is a [String] or [List<int>], depending on whether the
  /// underlying resource is binary or string based.
  ///
  /// The default implementation simply returns [contents]. Implementations
  /// should override this to return [T].
  T parseContents(dynamic contents) => _parserOverride != null
      ? _parserOverride(contents)
      : (parser != null ? parser(contents) : contents);

  /// For internal parsing before calling [parseContents].
  dynamic preParseContents(dynamic contents) => contents;

  /// This resource's path on the system.
  String get path => location;

  /// The [basename()] of the [path].
  String get basename => p.basename(path);

  Future<bool> get exists;

  /// Returns `null` if [exists] is `false`.
  Future<DateTime> get lastModified;

  /// Remove this resource from disk and sets [data] to `null`.
  ///
  /// Implementations should call super *after* performing the delete.
  @mustCallSuper
  Future<void> delete() async => _data = null;

  /// Persist the contents to disk.
  ///
  /// Implementations should call super *after* performing the write.
  @mustCallSuper
  Future<T> write(dynamic contents) async {
    Future.delayed(Duration(seconds: 3)).then((_) => exists.then((result) {
          if (!result)
            print('Warning: Write completed but target does not yet exist.');
        }));

    return _update(contents);
  }

  T _update(contents) => _data = parseContents(preParseContents(contents));
}

/// Network resources are fetched from the network and will cache a local copy.
///
/// The default [strategy] is to use [CacheStrategy.networkFirst] and fallback
/// on cache when the network is unavailable.
abstract class NetworkResource<T> extends AsyncResource<T> {
  NetworkResource(
      {@required String url,
      @required this.cache,
      this.maxAge,
      CacheStrategy strategy,
      this.parser})
      : strategy = strategy ?? CacheStrategy.networkFirst,
        super(location: url) {
    cache._parserOverride = parser;
  }

  /// The local copy of the data fetched from [url].
  final LocalResource<T> cache;

  /// Determines when the [cache] copy has expired and should be refetched.
  final Duration maxAge;

  final CacheStrategy strategy;

  /// This parser will override the [cache.parser].
  final Parser<T> parser;

  @override
  T get data => cache._data;

  /// The location of the data to fetch and cache.
  String get url => location;

  /// Returns `true` if [cache] does not exist, `false` if it exists but
  /// [maxAge] is null; otherwise compares the [cache]'s age to [maxAge].
  Future<bool> get isExpired async =>
      hasExpired(await cache.lastModified, maxAge);

  /// Retrieve the data from RAM if possible, otherwise fallback to cache or
  /// network, depending on the [strategy].
  ///
  /// If [forceReload] is `true` then this will fetch from the network, using
  /// the cache as a fallback unless [allowCacheFallback] is `false`.
  ///
  /// [allowCacheFallback] only affects network requests. The cache can still
  /// be used if it is not expired and [forceReload] is `false`.
  @override
  Future<T> get(
      {bool forceReload: false,
      bool allowCacheFallback: true,
      bool skipCacheWrite: false}) async {
    if (cache.data != null && !forceReload) {
      // print('${cache.basename}: Using previously loaded value.');
      return cache.data;
    } else if (forceReload ||
        strategy == CacheStrategy.networkFirst ||
        await isExpired) {
      print('${cache.basename}: Fetching from $url');
      final contents = await _tryFetchContents();
      if (contents != null) {
        print('$url Fetched.');
        if (!skipCacheWrite) {
          print('Updating cache...');
          return cache.write(contents);
        } else {
          return cache._update(contents);
        }
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
      print('Loading cached copy of ${cache.basename}');
      return cache.get();
    }
  }
}

enum CacheStrategy { networkFirst, cacheFirst }

bool hasExpired(DateTime date, Duration maxAge) {
  return date == null
      ? true
      : (maxAge == null ? false : new DateTime.now().difference(date) > maxAge);
}

/// Wraps an [AsyncResource], providing a stream of its outputs and a sink tied
/// to [AsyncResource.get()].
///
/// Remember to initialize the stream after it is created. For example:
///
/// ```
/// res = StreamedResource<String>(resource);
/// res.sink.add(false);
/// ```
class StreamedResource<T> {
  StreamedResource(this.resource) {
    _controller.stream.listen((forceReload) =>
        resource.get(forceReload: forceReload).then(_updateStream));
  }
  final AsyncResource<T> resource;
  final _controller = StreamController<bool>();
  final _stream = BehaviorSubject<T>();

  void dispose() {
    _controller.close();
    _stream.close();
  }

  void _updateStream(T data) {
    if (!_stream.isClosed) _stream.add(data);
  }

  /// The value passed will be forwarded to
  /// [AsyncResource.get(forceReload: value)].
  Sink<bool> get sink => _controller.sink;

  /// The output stream of values retrieved from [AsyncResource.get()].
  Stream<T> get stream => _stream.stream;
}
