import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:async_resource/async_resource.dart';

/// Wraps a [File] on a file system.
class FileResource<T> extends LocalResource<T> {
  FileResource(this.file,
      {this.binary: false,
      this.encoding: utf8,
      this.flushOnWrite: false,
      Parser<T> parse})
      : super(path: file.path, parse: parse);

  final File file;
  final bool binary;
  final bool flushOnWrite;
  final Encoding encoding;

  @override
  Future<bool> get exists => file.exists();

  @override
  Future<DateTime> get lastModified => file.lastModified();

  @override
  Future<void> write(contents) => binary
      ? file.writeAsBytes(contents, flush: flushOnWrite)
      : file.writeAsString(contents, flush: flushOnWrite, encoding: encoding);

  @override
  Future fetchContents() =>
      binary ? file.readAsBytes() : file.readAsString(encoding: encoding);
}
