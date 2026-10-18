import 'dart:async';

import 'package:brudcast_in_app/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

PlatformInAppMessage platformMessage(String id, {int createdAtMillis = 1700000000000, bool isRead = false}) =>
    PlatformInAppMessage(
      id: id,
      campaignId: 'c-$id',
      format: PlatformMessageFormat.modal,
      isTest: false,
      title: 'Title $id',
      preview: 'Preview $id',
      thumbnailUrl: 'https://cdn.example.com/$id.png',
      isRead: isRead,
      createdAtMillis: createdAtMillis,
      design: '{"schemaVersion":1}',
    );

final class FakeInAppHost implements InAppHostApi {
  final List<String> calls = [];
  final List<({int? beforeMillis, int limit})> lists = [];
  final List<Completer<PlatformInboxPage>> pending = [];

  @override
  Future<PlatformInboxPage> listInbox(int? beforeMillis, int limit) {
    lists.add((beforeMillis: beforeMillis, limit: limit));
    final completer = Completer<PlatformInboxPage>();
    pending.add(completer);
    return completer.future;
  }

  /// Answers the oldest unanswered list call.
  void answer(List<PlatformInAppMessage> messages, {bool hasMore = false, int unreadCount = 0}) =>
      pending.removeAt(0).complete(PlatformInboxPage(messages: messages, unreadCount: unreadCount, hasMore: hasMore));

  /// Fails the oldest unanswered list call.
  void fail() => pending.removeAt(0).completeError(PlatformException(code: 'network', message: 'offline'));

  @override
  Future<void> markRead(String messageId) async => calls.add('markRead $messageId');

  @override
  Future<void> delete(String messageId) async => calls.add('delete $messageId');

  @override
  Future<void> setMessageHandlerEnabled(bool enabled) async => calls.add('messageHandler $enabled');

  @override
  Future<void> reportClick(String messageId, String buttonId) async => calls.add('click $messageId $buttonId');

  @override
  Future<void> pauseDisplay() async => calls.add('pause');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Feeds unread counts into the event channel the inbox listens on.
StreamController<int> mockUnreadCounts() {
  final counts = StreamController<int>.broadcast();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
    const EventChannel('dev.flutter.pigeon.brudcast_in_app.InAppEvents.unreadCountChanges', pigeonMethodCodec),
    MockStreamHandler.inline(
      onListen: (arguments, sink) {
        counts.stream.listen(sink.success);
      },
    ),
  );
  return counts;
}
