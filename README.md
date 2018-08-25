# async_resource

Automatically cache network resources and use them when offline. Interface with local resources on any platform.

## Examples

### Flutter and native

Import `FileResource`.

```dart
import 'package:async_resource/file_resource.dart';
```

Define a resource.

```dart
// Flutter needs a valid directory to write to.
// `getApplicationDocumentsDirectory()` is in the `path_provider` package.
// Native applications do not need this step.
final path = (await getApplicationDocumentsDirectory()).path;

final myDataResource = HttpNetworkResource<MyData>(
  url: 'https://example.com/my-data.json',
  parser: (contents) => MyData.fromJson(contents),
  cache: FileResource(File('$path/my-data.json')),
  maxAge: Duration(minutes: 60),
  strategy: CacheStrategy.cacheFirst,
);
```

Basic usage

```dart
final myData = await myDataResource.get();
// or without `await`
myDataResource.get().then((myData) => print(myData));
```

Flutter pull-to-refresh example

```dart
class MyDataView extends StatefulWidget {
  @override
  _MyDataViewState createState() => _MyDataViewState();
}

class _MyDataViewState extends State<MyDataView> {
  bool refreshing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: RefreshIndicator(
            onRefresh: refresh,
            child: FutureBuilder<MyData>(
              future: myDataResource.get(forceReload: refreshing),
              initialData: myDataResource.data,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _buildView(snapshot.data);
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return Center(child: CircularProgressIndicator());
              },
            )));
  }

  Future<Null> refresh() async {
    setState(() => refreshing = true);
    refreshing = false;
  }
}
```

### Flutter using Shared Preferences

Import `SharedPrefsResource`.

```dart
import 'package:shared_prefs_resource/shared_prefs_resource.dart';
```

Definition

```dart
final themeResource = StringPrefsResource('theme');
```

Usage example

```dart
class ThemedApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ThemedAppState();
}

class _ThemedAppState extends BlocState<ThemedApp> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MyData>(
        future: themeResource.get(),
        initialData: themeResource.data,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MaterialApp(
                title: 'My themed app',
                theme: buildTheme(snapshot.data),
                home: HomePage());
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return Center(child: CircularProgressIndicator());
        },
      );
  }
}
```

### Web using service worker

Import browser-based resources.

```dart
import 'package:async_resource/browser_resource.dart';
```

Define the resource.

```dart
final myDataResource = ServiceWorkerResource<MyData>(
    cache: ServiceWorkerCacheEntry(
        name: config.cacheName,
        url: 'https://example.com/my-data.json',
        parser: (contents) => MyData.fromJson(contents),
        maxAge: Duration(minutes: 60)));
```

Usage

```dart
myDataResource.get();
```

### Web using local/session storage

Import browser-based resources.

```dart
import 'package:async_resource/browser_resource.dart';
```

Define

```dart
final themeResource = StorageEntry('theme');
final sessionResource = StorageEntry('token', type: StorageType.sessionStorage);
```

Use

```dart
themeResource.get();
sessionResource.get();
```