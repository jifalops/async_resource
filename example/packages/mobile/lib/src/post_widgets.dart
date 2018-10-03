import 'package:async_resource/async_resource.dart';
import 'package:async_resource_flutter/helpers.dart';
import 'package:flutter/material.dart';
import 'resources.dart';

/// Exposing this to `main.dart`. This is bad practice and for the example only.
Color textColor = Colors.black;

Widget _buildPost(Post post) => ListTile(
      title: Text('${post?.title}', style: TextStyle(color: textColor)),
      subtitle: Text('${post?.body}', style: TextStyle(color: textColor)),
      leading: Text('${post?.id}', style: TextStyle(color: textColor)),
      trailing:
          Text('user ${post?.userId}', style: TextStyle(color: textColor)),
    );

/// Since [AsyncResource] uses [Future]s instead of [Stream]s, it only needs to
/// be created once. See [StreamedPostsWithHelpers] for this same example with
/// streams.
///
/// This class uses only the [FutureHandler] helper.
class PostsWithHelpers extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () => resources.posts.get(forceReload: true),
        child: FutureHandler<Iterable<Post>>(
          future: resources.posts.get(),
          initialData: resources.posts.data,
          handler: (context, posts) =>
              ListView(children: posts.map(_buildPost).toList()),
        ),
      );
}

/// Plain usage of [AsyncResource].
class PostsWithoutHelpers extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () => resources.posts.get(forceReload: true),
        child: FutureBuilder<Iterable<Post>>(
            future: resources.posts.get(),
            initialData: resources.posts.data,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView(
                    children: snapshot.data.map(_buildPost).toList());
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
      );
}

/// [StreamedResource] use streams that must be managed as part of widget state.
/// More specifically, they must be created and destroyed when the widget
/// changes.
///
/// In this example, state management is handled by [ResourceProviderRoot]. See
/// [StreamedPostsWithoutHelpers] for an example that only uses plain Flutter
/// widgets to manage the resource.
class StreamedPostsWithHelpers extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ResourceProviderRoot<Iterable<Post>>(
        onInit: () => StreamedResource(resources.posts),
        // Builder introduces a new context so we can use the above provider.
        child: Builder(
          builder: (context) => RefreshIndicator(
                onRefresh: () async =>
                    ResourceProvider.of(context).sink.add(true),
                child: ResourceWidget<Iterable<Post>>(
                  (context, posts) => ListView(
                        children: posts.map(_buildPost).toList(),
                      ),
                ),
              ),
        ),
      );
}

/// Plain use of [StreamedResource]. This example manually implements
/// [ResourceProvider]. In practice you may have a class with multiple
/// resources, and in that case you would create your own provider class.
///
/// The name "provider" is likely going to fade as instead of extending
/// [InheritedWidget], new implementations will extend [InheritedModel], and
/// naming conventions will be to use "...Model" instead of "...Provider". Once
/// [InheritedModel] makes it to the beta channel (or 1.0 release), it will be
/// used in this package instead of InheritedWidget.
class StreamedPostsWithoutHelpers extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StreamedPostsWithoutHelpersState();
}

class _StreamedPostsWithoutHelpersState
    extends State<StreamedPostsWithoutHelpers> {
  StreamedResource<Iterable<Post>> resource;

  @override
  Widget build(BuildContext context) => ResourceProvider<Iterable<Post>>(
        resource: resource,
        // Builder introduces a new context so we can use the above provider.
        child: Builder(
          builder: (context) => RefreshIndicator(
                onRefresh: () async =>
                    ResourceProvider.of(context).sink.add(true),
                child: StreamBuilder<Iterable<Post>>(
                    stream: resource.stream,
                    initialData: resources.posts.data,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListView(
                            children: snapshot.data.map(_buildPost).toList());
                      } else if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    }),
              ),
        ),
      );

  @override
  void initState() {
    super.initState();
    resource = StreamedResource(resources.posts);
    resource.sink.add(false);
  }

  @override
  void dispose() {
    resource.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StreamedPostsWithoutHelpers oldWidget) {
    super.didUpdateWidget(oldWidget);
    resource.dispose();
    resource = StreamedResource(resources.posts);
  }
}
