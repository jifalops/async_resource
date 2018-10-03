import 'dart:html';
import 'package:async_resource/async_resource.dart';
import 'package:async_resource_example/config.dart';
import 'package:async_resource_example_web/src/resources.dart';

void main() {
  querySelector('#title').text = appName;
  final CheckboxInputElement checkbox = querySelector('#isDark');
  final streamTab = querySelector('#streamTab');
  final futureTab = querySelector('#futureTab');
  final content = querySelector('#content');

  resources.darkBackground.get().then((isDark) {
    checkbox.checked = isDark;
    document.body.className = isDark ? 'dark' : '';
  });

  checkbox.onChange.listen((e) {
    document.body.className = checkbox.checked ? 'dark' : '';
    resources.darkBackground.write('${checkbox.checked}');
  });

  void makePosts(Iterable<Post> posts) {
    content.innerHtml = '';
    content.children
        .addAll(posts.map((post) => DivElement()..innerHtml = postHtml(post)));
  }

  void fetchPosts() {
    content.text = 'Fetching posts...';
    if (streamTab.className == 'active') {
      final resource = StreamedResource(resources.posts);
      resource.sink.add(false);
      resource.stream.listen(makePosts);
    } else {
      resources.posts.get().then(makePosts);
    }
  }

  streamTab.onClick.listen((e) {
    if (streamTab.className != 'active') {
      futureTab.className = '';
      streamTab.className = 'active';
      fetchPosts();
    }
  });
  futureTab.onClick.listen((e) {
    if (futureTab.className != 'active') {
      streamTab.className = '';
      futureTab.className = 'active';
      fetchPosts();
    }
  });
}

String postHtml(Post post) => '''
    <div class="post">
      <div class="leading">${post.id}</div>
      <div class="content">
        <div class="title">${post.title}</div>
        <div class="body">${post.body}</div>
      </div>
      <div class="trailing">user ${post.userId}</div>
    </div>
  ''';
