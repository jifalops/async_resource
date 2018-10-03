import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:async_resource_flutter/async_resource_flutter.dart';
import 'package:async_resource/file_resource.dart';

import 'package:async_resource_example/resources.dart';
import 'package:async_resource_example/config.dart';

export 'package:async_resource_example/resources.dart';

MobileResources _resources;
MobileResources get resources => _resources;

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

  /// Do one-time initialization of [resources].
  static Future<MobileResources> init() async => _resources ??=
      MobileResources._((await getApplicationDocumentsDirectory()).path);
}
