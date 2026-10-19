# brudcast_flutter

![Brudcast: Reach Everyone, Every time](https://raw.githubusercontent.com/brudcast/brudcast-sdk-flutter/main/.github/assets/banner.svg)

[![pub package](https://img.shields.io/pub/v/brudcast_flutter.svg)](https://pub.dev/packages/brudcast_flutter)
[![CI](https://github.com/brudcast/brudcast-sdk-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/brudcast/brudcast-sdk-flutter/actions/workflows/ci.yml)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/brudcast/brudcast-sdk-flutter/blob/main/LICENSE)

The [Brudcast](https://brudcast.com) SDK for Flutter: sessions, identity, events and deep link
handling for in-app messaging and push notifications. It runs the native
[Android](https://github.com/brudcast/brudcast-sdk-android) and
[iOS](https://github.com/brudcast/brudcast-sdk-ios) SDKs, so storage, networking, the event queue,
triggers and message rendering are the same code a native app runs.

## Features

- Identify signed-in users with a hash computed on your server, and forget them on logout.
- Record events and screens that trigger in-app messages and segment users.
- Route deep links, URLs and custom events from messages and push taps to your app's router,
  including the tap that launches the app.
- Consent controls: opt out of campaign messages, or stop all event collection.
- Every call is safe before `initialize`, and nothing throws into your app.

Add the module packages for the channels you use:

| Package                                                         | Adds                                          |
| --------------------------------------------------------------- | --------------------------------------------- |
| [`brudcast_in_app`](https://pub.dev/packages/brudcast_in_app)   | In-app messages and the inbox                 |
| [`brudcast_push`](https://pub.dev/packages/brudcast_push)       | Push notifications through `firebase_messaging` |

A push-only app adds `brudcast_push` alone and never ships the in-app renderer.

## Platform support

| Android          | iOS                                       |
| ---------------- | ----------------------------------------- |
| API 24 and later | 14 and later, with Swift Package Manager  |

Web, macOS, Windows and Linux are not supported.

## Getting started

Add the packages:

```sh
flutter pub add brudcast_flutter brudcast_in_app brudcast_push
```

or in `pubspec.yaml`:

```yaml
dependencies:
  brudcast_flutter: ^0.2.2
  brudcast_in_app: ^0.2.2
  brudcast_push: ^0.2.2
```

The native iOS SDK ships only as a Swift package, so turn on Flutter's Swift Package Manager
integration. These plugins have no CocoaPods podspec.

```sh
flutter config --enable-swift-package-manager
```

Android needs no setup.

You need the publishable key (`bpk_...`) of an in-app application from the Brudcast dashboard. It
is public by design; never put the application's identity secret in the app.

## Usage

### Start the SDK

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

`BrudcastOptions` also takes `environment`, `logLevel`, `appearance`, and `appGroupIdentifier` for
an iOS notification service extension. `BrudcastEnvironment.local()` reaches a service on the
development machine: `10.0.2.2:8191` from the Android emulator, `localhost:8191` from the iOS
simulator.

### Identify the user

Compute the user hash on your server and hand it to the app with the user's session:

```txt
userHash = hex(HMAC-SHA256(identitySecret, externalId))
```

```dart
await Brudcast.identify(user.id, userHash: user.brudcastHash, traits: BrudcastTraits(email: user.email));
```

Call `Brudcast.reset()` on logout. The device keeps its id, and its push token stops reaching the
previous user.

### Record events and screens

```dart
Brudcast.track('checkout_started', {'total': 120, 'product': 'sneakers'});
Brudcast.screen('Checkout');
```

Properties hold strings, numbers, booleans and nulls; anything else is dropped with a warning.
Event names start with a letter and use at most 64 letters, digits and `_ . : -`.

### Handle links from messages

```dart
BrudcastActionResult handleAction(BrudcastAction action) {
  if (action.kind == BrudcastActionKind.deeplink && router.canOpen(action.value)) {
    router.open(action.value);
    return BrudcastActionResult.handled;
  }
  return BrudcastActionResult.useDefault;
}
```

Return `handled` to route the action yourself, or `useDefault` to let the SDK open it. The handler
may be `async` and has two seconds to answer. On Android, an action from a notification FCM drew
itself has `verified == false`, because another app could forge the tap; check it before opening a
private screen.

### Consent

```dart
Brudcast.optOut();          // no campaign messages; transactional ones still arrive
Brudcast.disableTracking(); // no events at all, for consent frameworks
```

## Additional information

- **Versions.** Keep `brudcast_flutter`, `brudcast_in_app` and `brudcast_push` on the same version.
  The changelog names the native Android and iOS SDK version each release runs.
- **Privacy.** The SDK collects a random device id, the user id you pass, the traits you pass, and
  interactions with messages. Nothing is shared with third parties. Requests carry
  `BrudcastSDK-Flutter/<version>` in their `User-Agent`.
- **Example.** A complete app is in
  [`example`](https://github.com/brudcast/brudcast-sdk-flutter/tree/main/example).
- **Documentation:** [docs.brudcast.com](https://docs.brudcast.com).
- **Issues and contributing:** [file an issue](https://github.com/brudcast/brudcast-sdk-flutter/issues)
  or read [CONTRIBUTING.md](https://github.com/brudcast/brudcast-sdk-flutter/blob/main/CONTRIBUTING.md).
  Report vulnerabilities privately, as
  [SECURITY.md](https://github.com/brudcast/brudcast-sdk-flutter/blob/main/SECURITY.md) describes.
- **License:** Apache License 2.0.
