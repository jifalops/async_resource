import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:async_resource/async_resource.dart';
import 'package:async_resource/file_resource.dart';
import 'package:async_resource/browser_resource.dart';
import 'package:http/http.dart' as http;

class MockClient extends Mock implements http.Client {}

class MockLocalResource<T> extends Mock implements LocalResource<T> {}

final errorUrl = 'https://example.com/error';
final stringFile = 'test/string.txt';
final stringListFile = 'test/string-list.txt';
final binaryFile = 'test/binary.bin';

final stringData = 'some data';
final stringListData = 'some\nmore\r\ndata';
final stringListDataList = ['some', 'more', 'data'];
final binaryData = [0, 1, 2];

void main() {
  final client = new MockClient();
  when(client.get(errorUrl, headers: null))
      .thenAnswer((_) async => new http.Response('', 404));
  when(client.get(stringFile, headers: null))
      .thenAnswer((_) async => new http.Response(stringData, 200));
  when(client.get(stringListFile, headers: null))
      .thenAnswer((_) async => new http.Response(stringListData, 200));
  when(client.get(binaryFile, headers: null))
      .thenAnswer((_) async => new http.Response.bytes(binaryData, 200));

  final localRes = new MockLocalResource();
  when(localRes.exists).thenAnswer((_) async => true);
  when(localRes.lastModified).thenAnswer((_) async => DateTime.now());
  when(localRes.write(dynamic)).thenAnswer((_) async => '');

  final stringRes = new HttpNetworkResource<String>(
      client: client, url: stringFile, cache: new MockLocalResource<String>());
}
