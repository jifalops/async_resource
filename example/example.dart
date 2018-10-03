//
// Copy of https://github.com/jifalops/async_resource/blob/master/example/packages/base/lib/resources.dart
//

/// The resources required by mobile and web versions of the app.
///
/// This isn't really necessary to do, but it helps make sure mobile and web
/// versions of the app are consistent, and makes designing a bit easier.
abstract class Resources {
  Resources({@required this.posts, @required this.darkBackground});

  final LocalResource<bool> darkBackground;

  /// [AsyncResource]s use [Future]s by default, but they can be wrapped in a
  /// [StreamedResource] to access them using a sink and stream.
  final NetworkResource<Iterable<Post>> posts;
}

//
// Copy of https://github.com/jifalops/async_resource/blob/master/example/packages/mobile/lib/src/resources.dart
//

/// Shorthand for `MobileResources.instance`.
MobileResources get resources => MobileResources._instance;

class MobileResources extends Resources {
  MobileResources._(this.path)
      : super(
          posts: HttpNetworkResource<Iterable<Post>>(
            url: postsUrl,
            parser: (contents) => Post.fromJsonArray(contents),
            cache: FileResource(File('$path/posts.json')),
            maxAge: Duration(days: 30),
            strategy: CacheStrategy.cacheFirst,
          ),
          darkBackground: BoolPrefsResource('darkBackground'),
        );

  final String path;

  static MobileResources _instance;
  static MobileResources get instance => _instance;

  /// Do one-time initialization of [resources].
  static Future<MobileResources> init() async => _instance ??=
      MobileResources._((await getApplicationDocumentsDirectory()).path);
}

//
// Copy of https://github.com/jifalops/async_resource/blob/master/example/packages/web/lib/src/resources.dart
//

/// This can be created synchronously because it does not need to wait for a
/// file from the system like the mobile version does.
final resources = WebResources._();

class WebResources extends Resources {
  WebResources._()
      : super(
          posts: ServiceWorkerResource<Iterable<Post>>(
            strategy: CacheStrategy.cacheFirst,
            cache: ServiceWorkerCacheEntry(
              name: 'async_resource_example',
              url: postsUrl,
              parser: (contents) => Post.fromJsonArray(contents),
              maxAge: Duration(days: 30),
            ),
          ),
          darkBackground: StorageEntry<bool>('darkBackground',
              parser: (contents) => contents == 'true'),
        );
}
