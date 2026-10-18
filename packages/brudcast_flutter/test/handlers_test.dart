import 'dart:async';

import 'package:brudcast_flutter/module.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns the handler answer', () async {
    expect(await runBrudcastHandler('handler', () => 'answer', 'fallback'), 'answer');
    expect(await runBrudcastHandler('handler', () async => 'later', 'fallback'), 'later');
  });

  test('falls back when the handler throws, synchronously or not', () async {
    expect(await runBrudcastHandler<String>('handler', () => throw StateError('boom'), 'fallback'), 'fallback');
    expect(await runBrudcastHandler<String>('handler', () async => throw StateError('boom'), 'fallback'), 'fallback');
  });

  test('falls back after two seconds without an answer', () {
    fakeAsync((async) {
      String? result;
      runBrudcastHandler('handler', () => Completer<String>().future, 'fallback').then((value) => result = value);

      async.elapse(const Duration(milliseconds: 1999));
      expect(result, isNull);
      async.elapse(const Duration(milliseconds: 2));
      expect(result, 'fallback');
    });
  });

  test('guarded calls return null instead of throwing', () async {
    expect(await guardBrudcastCall<int>('call', () async => throw StateError('boom')), isNull);
    expect(await guardBrudcastCall('call', () async => 3), 3);
  });
}
