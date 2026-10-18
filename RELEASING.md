# Releasing

The three packages are published to [pub.dev](https://pub.dev) together, with the same version as
the native SDKs they run. Pushing a `v<version>` tag runs `.github/workflows/release.yml`.

## Order

The Flutter packages pin the native SDKs exactly, so the native release comes first:

1. Release `brudcast-sdk-android` and `brudcast-sdk-ios` at the version, as their `RELEASING.md`
   files describe, and wait until the artifacts are on Maven Central and the tag is on GitHub.
2. Release the Flutter packages.

## Release

1. On a `docs/release-<version>` branch, set the version in:
   - `version:` in each package's `pubspec.yaml`, and the `brudcast_flutter` constraint in
     `brudcast_in_app` and `brudcast_push`;
   - `brudcastFlutterVersion` in `packages/brudcast_flutter/lib/src/version.dart`;
   - `brudcastSdkVersion` in each `android/build.gradle.kts`, and `exact:` in each
     `ios/<package>/Package.swift`;
   - the install lines in each package's `README.md`;
   - each `CHANGELOG.md`: move `Unreleased` under the version with today's date.

   Commit as `docs: release <version>` and merge to `main`. CI runs `scripts/check-version.sh`,
   which fails until all of them agree.
2. Tag `main` with `v<version>`, such as `v0.2.0`, and push the tag.
3. The workflow checks the tag against every file, then publishes `brudcast_flutter`, then
   `brudcast_in_app` and `brudcast_push`, each after approval in the `pub.dev` environment.

Versions on pub.dev cannot be replaced. A mistake needs a new version, or a retraction.

## One-time setup

- On pub.dev, for each package: **Admin** → **Automated publishing** → enable publishing from
  GitHub Actions for `brudcast/brudcast-sdk-flutter` with the tag pattern `v{{version}}`, and require
  the `pub.dev` environment. Publishing uses GitHub's OIDC token, so there is no stored credential.
- In the repository settings, create the `pub.dev` environment with required reviewers.

## Conventions

- Commits follow [Conventional Commits](https://www.conventionalcommits.org). A change that breaks
  the public API gets a `!` after its type, such as `feat!:`, before 1.0 too.
- Each `CHANGELOG.md` lists what an app using that package gets. How the packages are built and
  released belongs in the pull request and in this file.
