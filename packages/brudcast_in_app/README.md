# brudcast_in_app

![Brudcast: Reach Everyone, Every time](https://raw.githubusercontent.com/brudcast/brudcast-sdk-flutter/main/.github/assets/banner.svg)

[![pub package](https://img.shields.io/pub/v/brudcast_in_app.svg)](https://pub.dev/packages/brudcast_in_app)
[![CI](https://github.com/brudcast/brudcast-sdk-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/brudcast/brudcast-sdk-flutter/actions/workflows/ci.yml)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/brudcast/brudcast-sdk-flutter/blob/main/LICENSE)

In-app messages and the inbox for the [Brudcast Flutter SDK](https://pub.dev/packages/brudcast_flutter).
Messages are drawn by the native Android and iOS renderers, the same way they are in native apps,
over your Flutter UI with no widget to place.

## Features

- Modal, banner and full screen messages, triggered by events, screens and sessions, with display
  rules and frequency caps set in the dashboard.
- A message handler to show, suppress, defer or draw each message yourself.
- Pause and resume display, such as during checkout or a video.
- The native inbox screen, or your own: `InboxController` pages the inbox and follows its unread
  count, and `BrudcastInboxMessage` draws an entry with the native renderer.
- A live unread count for badges, kept in step across the user's devices.

## Platform support

| Android          | iOS                                       |
| ---------------- | ----------------------------------------- |
| API 24 and later | 14 and later, with Swift Package Manager  |

Messages show on Flutter's default `FlutterActivity`; no activity change is needed.

## Getting started

```sh
flutter pub add brudcast_flutter brudcast_in_app
```

or in `pubspec.yaml`:

```yaml
dependencies:
  brudcast_flutter: ^0.2.0
  brudcast_in_app: ^0.2.0
```

Set up [`brudcast_flutter`](https://pub.dev/packages/brudcast_flutter#getting-started), then add the
module when you initialise:

```dart
await Brudcast.initialize('bpk_...', const BrudcastOptions(modules: [BrudcastInApp.module]));
```

Messages then show as their triggers fire, from `Brudcast.track` and `Brudcast.screen`.

## Usage

### Control display

```dart
Brudcast.inApp.pauseDisplay();   // triggers that fire meanwhile are kept
Brudcast.inApp.resumeDisplay();

await Brudcast.inApp.setMessageHandler((message) async {
  if (onboarding) return BrudcastMessageDecision.defer;
  return BrudcastMessageDecision.show;
});
```

The handler has two seconds to answer, after which the message shows.

### Draw a message yourself

Return `BrudcastMessageDecision.custom`, draw the message from `message.designDocument`, and report
what happened:

```dart
Brudcast.inApp.reportImpression(message.id);
Brudcast.inApp.reportClick(message.id, buttonId);
Brudcast.inApp.reportDismiss(message.id);
```

### The native inbox

```dart
Brudcast.inApp.inbox.present(title: 'Inbox');
```

### An unread badge

```dart
ValueListenableBuilder<int>(
  valueListenable: Brudcast.inApp.inbox.unreadCount,
  builder: (context, unread, _) => Badge(
    isLabelVisible: unread > 0,
    label: Text('$unread'),
    child: const Icon(Icons.inbox),
  ),
)
```

### An inbox built in Flutter

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

Call `controller.loadMore()` near the end of the list and `controller.refresh()` on pull to
refresh; `markRead` and `delete` update the list at once and then every device.
`Brudcast.inApp.inbox.list` fetches pages directly.

`BrudcastInboxMessage` is a platform view that sizes itself to the design, so it fits in a scroll
view. Platform views are costly on Android in long lists: use it for a detail screen, and plain
Flutter tiles from `title`, `preview` and `thumbnailUrl` for the list.

## Additional information

- **Versions.** Keep this package on the same version as `brudcast_flutter`. The changelog names
  the native SDK version each release runs.
- **Example.** A complete app is in
  [`example`](https://github.com/brudcast/brudcast-sdk-flutter/tree/main/example).
- **Documentation:** [docs.brudcast.com](https://docs.brudcast.com).
- **Issues and contributing:** [file an issue](https://github.com/brudcast/brudcast-sdk-flutter/issues)
  or read [CONTRIBUTING.md](https://github.com/brudcast/brudcast-sdk-flutter/blob/main/CONTRIBUTING.md).
- **License:** Apache License 2.0.
