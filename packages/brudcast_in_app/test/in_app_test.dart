import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_in_app/brudcast_in_app.dart';
import 'package:brudcast_in_app/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Future<PlatformMessageDecision> sendMessage(PlatformInAppMessage message) async {
  const channel = 'dev.flutter.pigeon.brudcast_in_app.InAppFlutterApi.handleMessage';
  final reply = await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    channel,
    InAppFlutterApi.pigeonChannelCodec.encodeMessage([message]),
    (_) {},
  );
  final decoded = InAppFlutterApi.pigeonChannelCodec.decodeMessage(reply) as List<Object?>;
  return decoded.single! as PlatformMessageDecision;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeInAppHost host;
  late BrudcastInApp inApp;

  setUp(() {
    mockUnreadCounts();
    host = FakeInAppHost();
    inApp = BrudcastInApp.withHostApi(host);
  });

  test('Brudcast.inApp is the module instance', () {
    expect(Brudcast.inApp, same(BrudcastInApp.instance));
    expect(BrudcastInApp.module, const BrudcastModule('in_app'));
  });

  test('the message handler decides, and setting it enables the native handler', () async {
    BrudcastInAppMessage? received;
    await inApp.setMessageHandler((message) {
      received = message;
      return BrudcastMessageDecision.defer;
    });

    expect(await sendMessage(platformMessage('m1')), PlatformMessageDecision.deferred);
    expect(received!.id, 'm1');
    expect(received!.format, BrudcastMessageFormat.modal);
    expect(received!.designDocument, {'schemaVersion': 1});
    expect(host.calls, ['messageHandler true']);
  });

  test('a message shows when the handler throws', () async {
    await inApp.setMessageHandler((_) => throw StateError('boom'));

    expect(await sendMessage(platformMessage('m1')), PlatformMessageDecision.show);
  });

  test('a message shows when no handler is set', () async {
    await inApp.setMessageHandler(null);

    expect(await sendMessage(platformMessage('m1')), PlatformMessageDecision.show);
    expect(host.calls, ['messageHandler false']);
  });

  test('list converts the page and wraps failures', () async {
    final page = inApp.inbox.list(before: DateTime.fromMillisecondsSinceEpoch(5000), limit: 500);
    expect(host.lists.single, (beforeMillis: 5000, limit: 100));
    host.answer([platformMessage('a', isRead: true)], unreadCount: 3, hasMore: true);
    final result = await page;
    expect(result.unreadCount, 3);
    expect(result.hasMore, isTrue);
    expect(result.messages.single.isRead, isTrue);

    final failing = inApp.inbox.list();
    host.fail();
    await expectLater(failing, throwsA(isA<BrudcastInboxException>()));
  });

  test('designDocument is empty for a design that is not a JSON object', () {
    final message = BrudcastInAppMessage(
      id: 'm1',
      format: BrudcastMessageFormat.banner,
      title: '',
      preview: '',
      createdAt: DateTime(2026),
      design: 'not json',
    );
    expect(message.designDocument, isEmpty);
  });

  test('report calls reach native', () async {
    await inApp.reportClick('m1', 'buy');
    await inApp.pauseDisplay();

    expect(host.calls, ['click m1 buy', 'pause']);
  });
}
