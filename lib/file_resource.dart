import 'dart:io' show File;
import 'dart:async' show Future;
import 'dart:convert' show Encoding, utf8;
import 'package:async_resource/async_resource.dart';

export 'package:async_resource/async_resource.dart';
export 'dart:io' show File;

/// Wraps a [File] on a file system.
class FileResource<T> extends LocalResource<T> {
  FileResource(this.file,
      {this.binary: false,
      this.encoding: utf8,
      this.flushOnWrite: false,
      Parser<T> parser})
      : super(path: file.path, parser: parser);

  final File file;
  final bool binary;
  final bool flushOnWrite;

  /// Only used if [binary] is `false`.
  final Encoding encoding;

  @override
  Future<bool> get exists => file.exists();

  @override
  Future<DateTime> get lastModified async =>
      (await exists) ? file.lastModified() : null;

  @override
  Future<T> write(contents) {
    binary
        ? file.writeAsBytes(contents, flush: flushOnWrite)
        : file.writeAsString(contents, flush: flushOnWrite, encoding: encoding);
    return super.write(contents);
  }

  @override
  Future<void> delete() async {
    await file.delete();
    super.delete();
  }

  @override
  Future fetchContents() =>
      binary ? file.readAsBytes() : file.readAsString(encoding: encoding);
}
