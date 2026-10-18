# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the package uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Its version is the version of the
native Brudcast SDKs it runs. Before 1.0, a minor release may change the public API.

## [0.2.0] - Unreleased

### Added

- `Brudcast.push`: `setToken` for the FCM token from `firebase_messaging`, `requestPermission`, a
  live `permissionStatus`, and an asynchronous notification handler.
- `handleForegroundMessage`, which shows Brudcast notifications `firebase_messaging` delivers in the
  foreground on Android.
- `BrudcastPush.isBrudcastNotification`, pure Dart, for `firebase_messaging`'s background handler.
- Opens are recorded natively with no Dart code, including the tap that launches the app, on both
  platforms.
