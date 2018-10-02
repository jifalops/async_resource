import 'package:async_resource/browser_resource.dart';
import 'package:async_resource_example/resources.dart';
import 'package:async_resource_example/config.dart';

export 'package:async_resource_example/resources.dart';

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
