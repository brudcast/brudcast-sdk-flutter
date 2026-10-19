# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the package uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Each release names the native
Brudcast SDK version it runs. Before 1.0, a minor release may change the public API.

## [0.2.2] - 2026-10-19

### Changed

- Depends on `brudcast_flutter: ^0.2.2` instead of one exact version, so a later
  `brudcast_flutter` patch release no longer needs a release of this package. It runs the native
  Android and iOS SDKs 0.2.0.
- The 0.2.1 changes: the package version no longer follows the native SDK version. 0.2.1 of this
  package was not published.

## [0.2.1] - 2026-10-19

### Changed

- The package version no longer follows the native SDK version, so fixes to the Flutter layer ship
  without a native release. Each release names the native SDK version it runs. This one runs the
  native Android and iOS SDKs 0.2.0, the same as 0.2.0.

## [0.2.0] - 2026-10-18

### Added

- `Brudcast.inApp`: display pause and resume, sync, an asynchronous message handler, and impression,
  click and dismiss reports for messages the app draws itself.
- `Brudcast.inApp.inbox`: the native inbox screen, paging, mark read, delete and a live
  `unreadCount`.
- `InboxController`, a `ChangeNotifier` for inbox screens built in Flutter.
- `BrudcastInboxMessage`, which draws an inbox entry with the native renderer and sizes itself to
  the design.
- In-app messages show on a default `FlutterActivity` on Android.
