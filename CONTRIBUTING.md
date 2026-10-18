# Contributing

Thanks for helping improve the Brudcast Flutter SDK. This repository holds three plugins,
`brudcast_flutter`, `brudcast_in_app` and `brudcast_push`, and an example app, in one
[pub workspace](https://dart.dev/tools/pub/workspaces).

## Before you start

- **Bugs:** search the [issues](https://github.com/brudcast/brudcast-sdk-flutter/issues) first, then
  open one with the bug report form. A minimal project that reproduces the problem helps most.
- **Features:** open an issue to discuss the change before writing it. Behaviour that is not
  Flutter-specific belongs in the native SDKs first:
  [Android](https://github.com/brudcast/brudcast-sdk-android) and
  [iOS](https://github.com/brudcast/brudcast-sdk-ios).
- **Security problems:** never in a public issue. See [SECURITY.md](SECURITY.md).

## Set up

You need the current stable Flutter, Xcode for iOS, and JDK 17 with the Android SDK for Android.

```sh
git clone https://github.com/brudcast/brudcast-sdk-flutter.git
cd brudcast-sdk-flutter
flutter pub get
flutter config --enable-swift-package-manager
```

To build against native changes that are not released yet, see "Against unreleased native SDKs" in
the [README](README.md#against-unreleased-native-sdks).

## Make a change

1. Branch from `main`.
2. Keep each package's public API documented: every public member has a `///` comment.
3. If you change a channel in `pigeons/messages.dart`, regenerate and format the output, and
   commit it:

   ```sh
   (cd packages/brudcast_in_app && dart run pigeon --input pigeons/messages.dart && dart format lib/src/messages.g.dart)
   ```

4. Add tests: Dart unit tests in each package's `test` folder; the native glue is covered by
   Kotlin tests in `android/src/test` and Swift tests in `example/ios/RunnerTests`.
5. Add a line under `## [Unreleased]` in the `CHANGELOG.md` of each package an app would notice
   the change in.

## Check it

These are the checks CI runs:

```sh
scripts/check-version.sh
dart format --output=none --set-exit-if-changed $(git ls-files '*.dart')
for dir in packages/* example; do (cd "$dir" && flutter analyze --fatal-infos); done
for package in packages/*; do (cd "$package" && flutter test); done
(cd example && flutter build apk --debug)
(cd example && flutter build ios --simulator --no-codesign)
```

## Pull requests

- Commits follow [Conventional Commits](https://www.conventionalcommits.org), such as
  `feat(in-app): ...` or `fix(push): ...`. A change that breaks the public API gets a `!` after
  its type, before 1.0 too.
- Describe what changes for an app using the SDK, and how you tested it on each platform.
- CI must pass before review.

By contributing, you agree that your contributions are licensed under the
[Apache License 2.0](LICENSE), and to follow the [code of conduct](CODE_OF_CONDUCT.md).
