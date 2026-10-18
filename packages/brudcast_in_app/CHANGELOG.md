# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the package uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Its version is the version of the
native Brudcast SDKs it runs. Before 1.0, a minor release may change the public API.

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
