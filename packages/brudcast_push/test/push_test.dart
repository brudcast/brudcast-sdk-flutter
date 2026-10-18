import 'dart:async';

import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_push/brudcast_push.dart';
import 'package:brudcast_push/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakePushHost implements PushHostApi {
  final List<String> calls = [];
  Map<String, String>? forwarded;
  PlatformPushPermission permission = PlatformPushPermission.authorized;

  @override
  Future<void> setToken(String token) async => calls.add('setToken $token');

  @override
  Future<PlatformPushPermission> requestPermission(bool provisional) async {
    calls.add('requestPermission $provisional');
    return permission;
  }

  @override
  Future<void> setNotificationHandlerEnabled(bool enabled) async => calls.add('notificationHandler $enabled');

  @override
  Future<bool> handleForegroundMessage(Map<String, String> data, String? title, String? body, String? imageUrl) async {
    calls.add('foreground $title $body $imageUrl');
    forwarded = data;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<PlatformNotificationDecision> sendNotification(PlatformPushNotification notification) async {
  const channel = 'dev.flutter.pigeon.brudcast_push.PushFlutterApi.handleNotification';
  final reply = await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    channel,
    PushFlutterApi.pigeonChannelCodec.encodeMessage([notification]),
    (_) {},
  );
  final decoded = PushFlutterApi.pigeonChannelCodec.decodeMessage(reply) as List<Object?>;
  return decoded.single! as PlatformNotificationDecision;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakePushHost host;

  setUp(() => host = FakePushHost());

  test('Brudcast.push is the module instance', () {
    expect(Brudcast.push, same(BrudcastPush.instance));
    expect(BrudcastPush.module, const BrudcastModule('push'));
  });

  group('isBrudcastNotification', () {
    test('accepts data with a Brudcast message id', () {
      expect(
        BrudcastPush.isBrudcastNotification({'bc_mid': 'pm_1', 'bc_cid': 'c_1', 'click_url': 'myapp://shop'}),
        isTrue,
      );
    });

    test('refuses data without one, or with an empty one', () {
      expect(BrudcastPush.isBrudcastNotification({'google.message_id': '0:1'}), isFalse);
      expect(BrudcastPush.isBrudcastNotification({'bc_mid': ''}), isFalse);
      expect(BrudcastPush.isBrudcastNotification({'bc_mid': 7}), isFalse);
      expect(BrudcastPush.isBrudcastNotification(const {}), isFalse);
    });
  });

  group('handleForegroundMessage', () {
    test('forwards a Brudcast message on Android as strings', () async {
      final push = BrudcastPush.withHostApi(host, platform: TargetPlatform.android);

      final handled = await push.handleForegroundMessage(
        {'bc_mid': 'pm_1', 'count': 3, 'missing': null},
        title: 'Hi',
        body: 'There',
        imageUrl: 'https://cdn/x.png',
      );

      expect(handled, isTrue);
      expect(host.calls, ['foreground Hi There https://cdn/x.png']);
      expect(host.forwarded, {'bc_mid': 'pm_1', 'count': '3'});
    });

    test('leaves other messages to the app', () async {
      final push = BrudcastPush.withHostApi(host, platform: TargetPlatform.android);

      expect(await push.handleForegroundMessage({'from': 'other'}), isFalse);
      expect(host.calls, isEmpty);
    });

    test('does nothing on iOS, where the system shows it, but claims Brudcast messages', () async {
      final push = BrudcastPush.withHostApi(host, platform: TargetPlatform.iOS);

      expect(await push.handleForegroundMessage({'bc_mid': 'pm_1'}), isTrue);
      expect(host.calls, isEmpty);
    });
  });

  test('requestPermission returns the new status', () async {
    final push = BrudcastPush.withHostApi(host);
    host.permission = PlatformPushPermission.provisional;

    expect(await push.requestPermission(provisional: true), BrudcastPushPermission.provisional);
    expect(host.calls, ['requestPermission true']);
  });

  test('setToken reaches native', () async {
    await BrudcastPush.withHostApi(host).setToken('fcm-token');

    expect(host.calls, ['setToken fcm-token']);
  });

  group('the notification handler', () {
    final notification = PlatformPushNotification(messageId: 'pm_1', title: 'Sale', data: {'sku': '42'});

    test('decides, and setting it enables the native handler', () async {
      final push = BrudcastPush.withHostApi(host);
      BrudcastPushNotification? received;
      await push.setNotificationHandler((notification) {
        received = notification;
        return BrudcastNotificationDecision.suppress;
      });

      expect(await sendNotification(notification), PlatformNotificationDecision.suppress);
      expect(received, const BrudcastPushNotification(messageId: 'pm_1', title: 'Sale', data: {'sku': '42'}));
      expect(host.calls, ['notificationHandler true']);
    });

    test('a notification shows when the handler throws', () async {
      final push = BrudcastPush.withHostApi(host);
      await push.setNotificationHandler((_) async => throw StateError('boom'));

      expect(await sendNotification(notification), PlatformNotificationDecision.show);
    });
  });

  test('permissionStatus follows the native status', () async {
    final statuses = StreamController<PlatformPushPermission>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.flutter.pigeon.brudcast_push.PushEvents.permissionChanges', pigeonMethodCodec),
      MockStreamHandler.inline(onListen: (arguments, sink) => statuses.stream.listen(sink.success)),
    );
    final push = BrudcastPush.withHostApi(host);
    final status = push.permissionStatus;
    expect(status.value, BrudcastPushPermission.notDetermined);

    statuses.add(PlatformPushPermission.denied);
    await pumpEventQueue();

    expect(status.value, BrudcastPushPermission.denied);
    expect(push.permissionStatus, same(status));
  });
}
