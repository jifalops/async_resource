import 'dart:async' show Future;
import 'package:async_resource/async_resource.dart';
import 'dart:convert';

import 'package:flutter_mmkv/flutter_mmkv.dart';
export 'package:async_resource/async_resource.dart';

/// Resource for asyncResource with MMKV
class MMKVResource<T> extends LocalResource<T> {
  MMKVResource(this.key,
      this.path,
      {Parser<T> parser})
      : super(path: path , parser: parser);

  final String key;
  final String path;

  @override
  Future<bool> get exists async => await FlutterMmkv.containsKey(key);

  @override
  Future<DateTime> get lastModified async {
    bool exist = await exists;
    if (!exist)
      return null;
    var value = await FlutterMmkv.decodeString(key);
    Map<String, dynamic> contentPlusTime = jsonDecode(value);
    DateTime dateTime = DateTime.parse(contentPlusTime['lastModified']);
    return dateTime;
  }

  @override
  Future<T> write(contents) async {
    String lastModified = DateTime.now().toIso8601String();
    Map contentPlusTime = {
      'lastModified': lastModified,
      'contents': contents
    };
    await FlutterMmkv.encodeString(key, jsonEncode(contentPlusTime));
    return super.write(contents);
  }

  @override
  Future<void> delete() async {
    await FlutterMmkv.removeValueForKey(key);
    super.delete();
  }

  @override
  Future fetchContents() async {
    var value = await FlutterMmkv.decodeString(key);
    Map<String, dynamic> contentPlusTime = jsonDecode(value);
    return contentPlusTime['contents'];
  }
}
