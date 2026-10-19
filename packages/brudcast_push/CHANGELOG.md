# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the package uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Each release names the native
Brudcast SDK version it runs. Before 1.0, a minor release may change the public API.

## [0.2.1] - 2026-10-19

### Changed

- The package version no longer follows the native SDK version, so fixes to the Flutter layer ship
  without a native release. Each release names the native SDK version it runs. This one runs the
  native Android and iOS SDKs 0.2.0, the same as 0.2.0.

## [0.2.0] - 2026-10-18

### Added

- `Brudcast.push`: `setToken` for the FCM token from `firebase_messaging`, `requestPermission`, a
  live `permissionStatus`, and an asynchronous notification handler.
- `handleForegroundMessage`, which shows Brudcast notifications `firebase_messaging` delivers in the
  foreground on Android.
- `BrudcastPush.isBrudcastNotification`, pure Dart, for `firebase_messaging`'s background handler.
- Opens are recorded natively with no Dart code, including the tap that launches the app, on both
  platforms.
