# brudcast_in_app

In-app messages and the inbox for the [Brudcast Flutter SDK](https://pub.dev/packages/brudcast_flutter).
Messages are drawn by the native Android and iOS renderers, the same way they are in native apps:
modals, banners and full screen messages appear over your Flutter UI with no widget to place.

## Install

```yaml
dependencies:
  brudcast_flutter: ^0.2.0
  brudcast_in_app: ^0.2.0
```

Add the module when you initialise:

```dart
await Brudcast.initialize('bpk_...', const BrudcastOptions(modules: [BrudcastInApp.module]));
```

Messages show on Flutter's default `FlutterActivity` on Android, and on any Flutter view controller
on iOS. Trigger them with events and screens from `Brudcast.track` and `Brudcast.screen`.

## Control display

```dart
Brudcast.inApp.pauseDisplay();   // during checkout or a video; triggers are kept
Brudcast.inApp.resumeDisplay();

await Brudcast.inApp.setMessageHandler((message) async {
  if (onboarding) return BrudcastMessageDecision.defer;
  return BrudcastMessageDecision.show;
});
```

The handler has two seconds to answer, after which the message shows. Return `custom` to draw a
message yourself from `message.designDocument`, then report what happened:

```dart
Brudcast.inApp.reportImpression(message.id);
Brudcast.inApp.reportClick(message.id, buttonId);
Brudcast.inApp.reportDismiss(message.id);
```

## The inbox

The native inbox screen:

```dart
Brudcast.inApp.inbox.present(title: 'Inbox');
```

A badge:

```dart
ValueListenableBuilder<int>(
  valueListenable: Brudcast.inApp.inbox.unreadCount,
  builder: (context, unread, _) => Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.inbox)),
)
```

An inbox built in Flutter, with `InboxController` paging and following the unread count, and
`BrudcastInboxMessage` drawing an entry with the native renderer:

```dart
final controller = InboxController();

ListenableBuilder(
  listenable: controller,
  builder: (context, _) => ListView(
    children: [
      for (final message in controller.messages)
        ListTile(
          title: Text(message.title),
          subtitle: Text(message.preview),
          onTap: () {
            controller.markRead(message);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => Scaffold(body: BrudcastInboxMessage(message: message, expand: true)),
            ));
          },
        ),
    ],
  ),
);
```

Call `controller.loadMore()` near the end of the list and `controller.refresh()` on pull to refresh;
`markRead` and `delete` update the list at once. `Brudcast.inApp.inbox.list` fetches pages directly.

`BrudcastInboxMessage` is a platform view and sizes itself to the design, so it fits in a scroll
view. Platform views are costly on Android in long lists: use it for a detail screen, and plain
Flutter tiles from `title`, `preview` and `thumbnailUrl` for the list.

## License

Apache License 2.0.
