# brudcast_push

![Brudcast: Reach Everyone, Every time](https://raw.githubusercontent.com/brudcast/brudcast-sdk-flutter/main/.github/assets/banner.svg)

[![pub package](https://img.shields.io/pub/v/brudcast_push.svg)](https://pub.dev/packages/brudcast_push)
[![CI](https://github.com/brudcast/brudcast-sdk-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/brudcast/brudcast-sdk-flutter/actions/workflows/ci.yml)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/brudcast/brudcast-sdk-flutter/blob/main/LICENSE)

Push notifications for the [Brudcast Flutter SDK](https://pub.dev/packages/brudcast_flutter).
Brudcast sends through FCM, and this package works alongside
[`firebase_messaging`](https://pub.dev/packages/firebase_messaging), which owns the Firebase
integration.

## Features

- Registers the FCM token for the signed-in user, and detaches it on logout.
- Records opens natively, with no Dart code, including the tap that launches the app, and routes
  the notification's link through the action handler.
- Shows Brudcast notifications that arrive in the foreground on Android, which `firebase_messaging`
  leaves to the app.
- Asks for notification permission, and reports the status as it changes.
- A handler to show or suppress notifications that arrive while the app is open.

## Platform support

| Android          | iOS                                       |
| ---------------- | ----------------------------------------- |
| API 24 and later | 14 and later, with Swift Package Manager  |

## Getting started

```sh
flutter pub add brudcast_flutter brudcast_push firebase_core firebase_messaging
```

or in `pubspec.yaml`:

```yaml
dependencies:
  brudcast_flutter: ^0.2.1
  brudcast_push: ^0.2.1
  firebase_core: ^4.0.0
  firebase_messaging: ^16.0.0
```

1. Set up [`brudcast_flutter`](https://pub.dev/packages/brudcast_flutter#getting-started), and
   Firebase for both platforms as its documentation describes.
2. Link the in-app application to a push application in the Brudcast dashboard.
3. Add the module when you initialise:

   ```dart
   await Brudcast.initialize('bpk_...', const BrudcastOptions(modules: [BrudcastPush.module]));
   ```

**Android:** do not declare `BrudcastFirebaseMessagingService` from the native SDK in your
manifest. Android gives `MESSAGING_EVENT` to one service, and `firebase_messaging` declares its own.
The small icon is the one set for FCM in the manifest's
`com.google.firebase.messaging.default_notification_icon` meta-data, then a plain bell.

**iOS:** add the Push Notifications capability to the Runner target. The plugin makes Flutter's app
delegate the notification center's delegate when nothing else has set one, so every plugin
receives notification callbacks; if your app sets its own delegate, forward `didReceive` and
`willPresent` to `super`. For images and `push_received`, add a Notification Service Extension
whose class extends `BrudcastNotificationServiceExtension` from the `BrudcastNotificationService`
product of [brudcast-sdk-ios](https://github.com/brudcast/brudcast-sdk-ios), share an App Group
between it and the app, and pass the group as `BrudcastOptions.appGroupIdentifier`.

## Usage

### Connect firebase_messaging

```dart
await Firebase.initializeApp();
final messaging = FirebaseMessaging.instance;

final token = await messaging.getToken();
if (token != null) Brudcast.push.setToken(token);
messaging.onTokenRefresh.listen(Brudcast.push.setToken);

FirebaseMessaging.onMessage.listen((message) {
  Brudcast.push.handleForegroundMessage(
    message.data,
    title: message.notification?.title,
    body: message.notification?.body,
    imageUrl: message.notification?.android?.imageUrl,
  );
});
```

`handleForegroundMessage` shows Brudcast notifications on Android and does nothing on iOS, where the
system shows them, so call it on both platforms. It returns false for messages from other senders.

`firebase_messaging`'s background handler runs in a separate isolate where the plugin is not
attached. Only `BrudcastPush.isBrudcastNotification(message.data)` is safe there, and Brudcast
notifications need nothing in it.

### Ask for permission

```dart
final status = await Brudcast.push.requestPermission();

ValueListenableBuilder<BrudcastPushPermission>(
  valueListenable: Brudcast.push.permissionStatus,
  builder: (context, status, _) => Text(status.name),
);
```

Android 13 and later and iOS show a prompt. `requestPermission(provisional: true)` asks iOS for
quiet delivery without one.

### Foreground notifications

```dart
await Brudcast.push.setNotificationHandler((notification) async {
  return onChatScreen ? BrudcastNotificationDecision.suppress : BrudcastNotificationDecision.show;
});
```

The handler has two seconds to answer, after which the notification shows. On iOS, when
`firebase_messaging` is installed it decides how foreground notifications are presented, from
`setForegroundNotificationPresentationOptions`, and the handler is not asked.

## Additional information

- **Versions.** Keep this package on the same version as `brudcast_flutter`. The changelog names
  the native SDK version each release runs.
- **Example.** A complete app, with the whole `firebase_messaging` wiring, is in
  [`example`](https://github.com/brudcast/brudcast-sdk-flutter/tree/main/example).
- **Documentation:** [docs.brudcast.com](https://docs.brudcast.com).
- **Issues and contributing:** [file an issue](https://github.com/brudcast/brudcast-sdk-flutter/issues)
  or read [CONTRIBUTING.md](https://github.com/brudcast/brudcast-sdk-flutter/blob/main/CONTRIBUTING.md).
- **License:** Apache License 2.0.
