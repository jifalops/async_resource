import 'dart:async';
import 'package:async_resource/file_resource.dart';
import 'package:async_resource_flutter/async_resource_flutter.dart';
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

  /// To be called by the app when a path for writing files to is known.
  /// This is typically [getApplicationDocumentsDirectory()] or
  /// [getExternalStorageDirectory()] from the `path_provider` package.
  static Future<MobileResources> init(String path) async =>
      _resources ??= MobileResources._(path);
}


