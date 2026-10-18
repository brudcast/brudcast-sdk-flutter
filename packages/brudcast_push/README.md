# brudcast_push

Push notifications for the [Brudcast Flutter SDK](https://pub.dev/packages/brudcast_flutter).
Brudcast sends through FCM, and this package works alongside
[`firebase_messaging`](https://pub.dev/packages/firebase_messaging), which owns the Firebase
integration. Opens are recorded natively, with no Dart code, including the tap that launches the
app.

## Install

```yaml
dependencies:
  brudcast_flutter: ^0.2.0
  brudcast_push: ^0.2.0
  firebase_core: ^4.0.0
  firebase_messaging: ^16.0.0
```

Set up Firebase for both platforms as its documentation describes, then add the module:

```dart
await Brudcast.initialize('bpk_...', const BrudcastOptions(modules: [BrudcastPush.module]));
```

Push needs the in-app application linked to a push application in the Brudcast dashboard.

## Connect firebase_messaging

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

`firebase_messaging` does not show notifications that arrive in the foreground on Android, so
`handleForegroundMessage` shows Brudcast's. It does nothing on iOS, where the system shows them, so
call it on both platforms. It returns false for messages from other senders.

`firebase_messaging`'s background handler runs in a separate isolate where the plugin is not
attached. Only `BrudcastPush.isBrudcastNotification(message.data)` is safe there, and Brudcast
notifications need nothing in it.

## Permission

```dart
final status = await Brudcast.push.requestPermission();

ValueListenableBuilder<BrudcastPushPermission>(
  valueListenable: Brudcast.push.permissionStatus,
  builder: (context, status, _) => Text(status.name),
);
```

Android 13 and later and iOS show a prompt. `requestPermission(provisional: true)` asks iOS for
quiet delivery without one.

## Foreground notifications

```dart
await Brudcast.push.setNotificationHandler((notification) async {
  return onChatScreen ? BrudcastNotificationDecision.suppress : BrudcastNotificationDecision.show;
});
```

The handler has two seconds to answer, after which the notification shows. On iOS, when
`firebase_messaging` is installed it decides how foreground notifications are presented, from
`setForegroundNotificationPresentationOptions`, and the handler is not asked.

## Android

- Do not declare `BrudcastFirebaseMessagingService` from the native SDK in your manifest. Android
  gives `MESSAGING_EVENT` to one service, and `firebase_messaging` declares its own.
- The notification's small icon is the one set for FCM in the manifest's
  `com.google.firebase.messaging.default_notification_icon` meta-data, then a plain bell.

## iOS

- Add the Push Notifications capability to the Runner target.
- The plugin makes Flutter's app delegate the notification center's delegate when nothing else has
  set one, so every plugin receives notification callbacks. If your app sets its own delegate,
  forward `didReceive` and `willPresent` to `super`.
- For images and `push_received`, add a Notification Service Extension target whose class extends
  `BrudcastNotificationServiceExtension` from the `BrudcastNotificationService` product of
  [brudcast-sdk-ios](https://github.com/brudcast/brudcast-sdk-ios), share an App Group between it
  and the app, and pass the group as `BrudcastOptions.appGroupIdentifier`.

## License

Apache License 2.0.
