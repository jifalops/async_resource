@TestOn('vm')

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:async_resource/async_resource.dart';

class MockLocalResource<T> extends Mock implements LocalResource<T> {}

void main() {
  test('No platform dependencies', () {
    expect(new HttpNetworkResource(url: '', cache: new MockLocalResource()),
        isNotNull);
  });
}
