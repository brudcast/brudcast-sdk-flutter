# brudcast_flutter

The Brudcast SDK for Flutter: sessions, identity, events and the action handler, on Android and iOS.
It runs the native [Android](https://github.com/brudcast/brudcast-sdk-android) and
[iOS](https://github.com/brudcast/brudcast-sdk-ios) SDKs, so storage, networking, the event queue,
triggers and message rendering are the same code a native app runs.

| Package                                                     | What it adds                                                        |
| ----------------------------------------------------------- | ------------------------------------------------------------------- |
| `brudcast_flutter`                                          | Core: configuration, identity, events, the action handler. Required |
| [`brudcast_in_app`](https://pub.dev/packages/brudcast_in_app) | In-app messages and the inbox                                       |
| [`brudcast_push`](https://pub.dev/packages/brudcast_push)     | Push notifications through `firebase_messaging`                     |

A push-only app adds `brudcast_push` alone and never ships the in-app renderer.

## Install

```yaml
dependencies:
  brudcast_flutter: ^0.2.0
  brudcast_in_app: ^0.2.0
  brudcast_push: ^0.2.0
```

- **Android:** API 24 (Flutter's minimum) and later.
- **iOS:** 14 and later, with Flutter's Swift Package Manager integration on. The native iOS SDK
  ships only as a Swift package, so these plugins have no CocoaPods podspec:

  ```sh
  flutter config --enable-swift-package-manager
  ```

The package version is the version of the native SDKs it runs: `brudcast_flutter` 0.2.0 runs the
Android and iOS SDKs 0.2.0.

## Start

Call `initialize` once, before `runApp`. Set the action handler first, so a push tap that launched
the app reaches it.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Brudcast.setActionHandler(handleAction);
  await Brudcast.initialize(
    'bpk_...',
    const BrudcastOptions(
      modules: [BrudcastInApp.module, BrudcastPush.module],
      accentColor: Color(0xFF3355FF),
    ),
  );
  runApp(const MyApp());
}
```

The publishable key is public by design. Never put the application's identity secret in the app.
Every other call may come before `initialize`; the native SDK holds it until it starts.

`BrudcastOptions` also takes `environment` (`BrudcastEnvironment.local()` reaches a service on the
development machine: `10.0.2.2:8191` from the Android emulator, `localhost:8191` from the iOS
simulator), `logLevel`, `appearance`, and `appGroupIdentifier` for an iOS notification service
extension.

## Identify the user

Compute the user hash on your server and hand it to the app with the user's session:

```txt
userHash = hex(HMAC-SHA256(identitySecret, externalId))
```

```dart
await Brudcast.identify(user.id, userHash: user.brudcastHash, traits: BrudcastTraits(email: user.email));
```

Call `Brudcast.reset()` on logout. The device keeps its id, and its push token stops reaching the
previous user.

## Events and screens

```dart
Brudcast.track('checkout_started', {'total': 120, 'product': 'sneakers'});
Brudcast.screen('Checkout');
```

Properties hold strings, numbers, booleans and nulls. Anything else is dropped with a warning.
Event names start with a letter and use at most 64 letters, digits and `_ . : -`;
`Brudcast.isValidEventName` checks one.

## Links from messages

In-app buttons and push taps hand their deep links, URLs and custom events to the action handler.
Return `handled` to route it yourself, or `useDefault` to let the SDK open it:

```dart
BrudcastActionResult handleAction(BrudcastAction action) {
  if (action.kind == BrudcastActionKind.deeplink && router.canOpen(action.value)) {
    router.open(action.value);
    return BrudcastActionResult.handled;
  }
  return BrudcastActionResult.useDefault;
}
```

The handler may be `async`, and has two seconds to answer before the default runs. On Android, an
action from a notification FCM drew itself has `verified == false`, because another app could forge
the tap; check it before opening a private screen.

## Behaviour

- No call throws into the app. Failures are logged under the `Brudcast` name.
- Events are stored on the device and sent in batches. `Brudcast.disableTracking()` stops all
  collection, for consent frameworks.
- The device id is a random UUID the native SDK keeps, never an advertising id.
- Requests carry `BrudcastSDK-Flutter/<version>` in their `User-Agent`.

## License

Apache License 2.0.
