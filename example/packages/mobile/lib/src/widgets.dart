import 'package:async_resource/async_resource.dart';
import 'package:async_resource_flutter/async_resource_flutter.dart';
import 'package:async_resource_example/resources.dart';
import 'package:flutter/widgets.dart';

/// Example usage of [ResourceProvider].
class PostsProvider extends ResourceProvider<Iterable<Post>> {
  PostsProvider(StreamedResource<Iterable<Post>> streamedPosts, Widget child,
      {Key key})
      : super(key: key, resource: streamedPosts, child: child);
}
