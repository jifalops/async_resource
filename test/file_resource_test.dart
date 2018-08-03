@TestOn('!browser')

import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:async_resource/async_resource.dart';
import 'package:async_resource/file_resource.dart';
import 'package:http/http.dart' as http;

class MockClient extends Mock implements http.Client {}

final errorUrl = 'https://example.com/error';
final stringPath = 'test/string.txt';
final stringListPath = 'test/string-list.txt';
final binaryPath = 'test/binary.bin';

final stringData = 'some data';
final stringListData = 'some\nmore\r\ndata';
final stringListDataList = ['some', 'more', 'data'];
final binaryData = [0, 1, 2];

final File stringFile = new File(stringPath);
final File stringListFile = new File(stringListPath);
final File binaryFile = new File(binaryPath);

void main() {
  final client = new MockClient();
  when(client.get(errorUrl, headers: null))
      .thenAnswer((_) async => new http.Response('', 404));
  when(client.get(stringPath, headers: null))
      .thenAnswer((_) async => new http.Response(stringData, 200));
  when(client.get(stringListPath, headers: null))
      .thenAnswer((_) async => new http.Response(stringListData, 200));
  when(client.get(binaryPath, headers: null))
      .thenAnswer((_) async => new http.Response.bytes(binaryData, 200));

  final stringRes = new HttpNetworkResource(
      client: client, url: stringPath, cache: new FileResource(stringFile));
  final stringListRes = new HttpNetworkResource(
      client: client,
      url: stringPath,
      cache: new FileResource(stringListFile,
          parser: (contents) => contents.split(new RegExp(r'\r?\n'))));
  final binaryRes = new HttpNetworkResource(
      client: client, url: binaryPath, cache: new FileResource(binaryFile));

  final expiredRes = new HttpNetworkResource(
      client: client,
      url: stringPath,
      cache: new FileResource(stringFile, flushOnWrite: true),
      maxAge: new Duration(microseconds: 1));
  final errorRes = new HttpNetworkResource(
      client: client,
      url: errorUrl,
      cache: new FileResource(stringFile),
      maxAge: new Duration(microseconds: 1));

  test('Data is null if fetch fails and there is no cache file.', () async {
    expect(await errorRes.get(), isNull);
  });

  group('Correct data fetched and written to cache.', () {
    test('String data.', () async {
      expect(await stringRes.get(), stringData);
    });
    test('String list data.', () async {
      expect(await stringListRes.get(), stringListDataList);
    });
    test('Binary data.', () async {
      expect(await binaryRes.get(), binaryData);
    });

    // Data returns without waiting for the file write to complete.
    // These might fail if the write hasn't completed, but [File] might
    // handle the write-then-read situation internally.
    test('String file.', () async {
      expect(await stringRes.cache.get(forceReload: true), stringData);
    });
    test('String list file.', () async {
      expect(
          await stringListRes.cache.get(forceReload: true), stringListDataList);
    });
    test('Binary file.', () async {
      expect(await binaryRes.cache.get(forceReload: true), binaryData);
    });
  });

  test(
      'Data is returned if the fetch fails but the cache file exists, even if it is expired.',
      () async {
    expect(await errorRes.get(forceReload: true), stringData);
  });

  // This usually fails because the modified times are usually equal even
  // when the file is overwritten.
  test('Getting expired data automatically refreshes from the network.',
      () async {
    final oldTime = await expiredRes.cache.lastModified;
    await expiredRes.get();
    await new Future.delayed(new Duration(seconds: 2));
    final newTime = new File(expiredRes.cache.path).lastModifiedSync();
    expect(oldTime.isBefore(newTime), true);
  });

  test('Cleanup created files', () async {
    expect((await stringFile.delete()).existsSync(), false);
    expect((await stringListFile.delete()).existsSync(), false);
    expect((await binaryFile.delete()).existsSync(), false);
  });
}
