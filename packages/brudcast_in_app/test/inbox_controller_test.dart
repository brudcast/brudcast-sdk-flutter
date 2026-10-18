import 'package:brudcast_in_app/brudcast_in_app.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeInAppHost host;
  late BrudcastInApp inApp;

  setUp(() {
    mockUnreadCounts();
    host = FakeInAppHost();
    inApp = BrudcastInApp.withHostApi(host);
  });

  tearDown(() => inApp.inbox.dispose());

  test('loads the first page on creation', () async {
    final controller = InboxController(inbox: inApp.inbox, pageSize: 2);
    expect(controller.isLoading, isTrue);
    expect(host.lists.single, (beforeMillis: null, limit: 2));

    host.answer([platformMessage('a'), platformMessage('b')], hasMore: true);
    await pumpEventQueue();

    expect(controller.isLoading, isFalse);
    expect(controller.messages.map((message) => message.id), ['a', 'b']);
    expect(controller.messages.first.thumbnailUrl, Uri.parse('https://cdn.example.com/a.png'));
    expect(controller.messages.first.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    expect(controller.hasMore, isTrue);
  });

  test('loads older pages from the last entry and skips entries it already has', () async {
    final controller = InboxController(inbox: inApp.inbox, pageSize: 2);
    host.answer([
      platformMessage('a', createdAtMillis: 3000),
      platformMessage('b', createdAtMillis: 2000),
    ], hasMore: true);
    await pumpEventQueue();

    final more = controller.loadMore();
    expect(host.lists.last, (beforeMillis: 2000, limit: 2));
    host.answer([platformMessage('b', createdAtMillis: 2000), platformMessage('c', createdAtMillis: 1000)]);
    await more;

    expect(controller.messages.map((message) => message.id), ['a', 'b', 'c']);
    expect(controller.hasMore, isFalse);

    await controller.loadMore();
    expect(host.lists, hasLength(2));
  });

  test('ignores loadMore while a page is loading', () async {
    final controller = InboxController(inbox: inApp.inbox);
    await controller.loadMore();

    expect(host.lists, hasLength(1));
  });

  test('a refresh during a load wins over the older load', () async {
    final controller = InboxController(inbox: inApp.inbox);
    final refreshed = controller.refresh();
    host.answer([platformMessage('stale')]);
    host.answer([platformMessage('fresh')]);
    await refreshed;

    expect(controller.messages.map((message) => message.id), ['fresh']);
    expect(controller.isLoading, isFalse);
  });

  test('keeps the entries and reports the error when a load fails', () async {
    final controller = InboxController(inbox: inApp.inbox);
    host.answer([platformMessage('a')], hasMore: true);
    await pumpEventQueue();

    final more = controller.loadMore();
    host.fail();
    await more;

    expect(controller.error, isA<BrudcastInboxException>().having((error) => error.code, 'code', 'network'));
    expect(controller.messages.map((message) => message.id), ['a']);

    final retry = controller.refresh();
    host.answer([platformMessage('a')]);
    await retry;
    expect(controller.error, isNull);
  });

  test('marks an entry read in the list at once, and once only', () async {
    final controller = InboxController(inbox: inApp.inbox);
    host.answer([platformMessage('a'), platformMessage('b')]);
    await pumpEventQueue();
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.markRead(controller.messages.first);
    await controller.markRead(controller.messages.first);

    expect(controller.messages.first.isRead, isTrue);
    expect(controller.messages.last.isRead, isFalse);
    expect(host.calls, ['markRead a']);
    expect(notified, 1);
  });

  test('deletes an entry from the list at once', () async {
    final controller = InboxController(inbox: inApp.inbox);
    host.answer([platformMessage('a'), platformMessage('b')]);
    await pumpEventQueue();

    await controller.delete(controller.messages.first);

    expect(controller.messages.map((message) => message.id), ['b']);
    expect(host.calls, ['delete a']);
  });

  test('follows the live unread count', () async {
    final counts = mockUnreadCounts();
    final controller = InboxController(inbox: inApp.inbox);
    var notified = 0;
    controller.addListener(() => notified++);
    await pumpEventQueue();

    counts.add(4);
    await pumpEventQueue();

    expect(controller.unreadCount, 4);
    expect(notified, greaterThan(0));
    controller.dispose();
  });
}
