# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the package uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Each release names the native
Brudcast SDK version it runs. Before 1.0, a minor release may change the public API.

## [0.2.2] - 2026-10-19

### Changed

- Released with `brudcast_in_app` and `brudcast_push` 0.2.2, which now accept later
  `brudcast_flutter` patch versions. No changes to this package. It runs the native Android and
  iOS SDKs 0.2.0.

## [0.2.1] - 2026-10-19

### Changed

- The package version no longer follows the native SDK version, so fixes to the Flutter layer ship
  without a native release. Each release names the native SDK version it runs. This one runs the
  native Android and iOS SDKs 0.2.0, the same as 0.2.0.

## [0.2.0] - 2026-10-18

### Added

- `Brudcast.initialize`, `identify`, `reset`, `track`, `screen`, `optOut`, `optIn`,
  `disableTracking`, `enableTracking`, `flush` and `deviceId` over the native Android and iOS SDKs
  0.2.0.
- `Brudcast.setActionHandler` with an asynchronous Dart handler. A push tap that launched the app
  waits up to five seconds for the handler to be set, so cold-start deep links reach the app's
  router.
- Property values are checked in Dart: anything but strings, finite numbers, booleans and nulls is
  dropped with a warning before it crosses the channel.
- Requests carry `BrudcastSDK-Flutter/<version>` in their `User-Agent`.
