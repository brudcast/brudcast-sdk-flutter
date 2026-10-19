# Releasing

The three packages are published to [pub.dev](https://pub.dev) together, with one version of their
own. Pushing a `v<version>` tag runs `.github/workflows/release.yml`.

## Versions

The package version and the native SDK version are separate:

- **The package version** follows [Semantic Versioning](https://semver.org) for the Dart API and
  the packaging. All three packages share it, and `brudcast_in_app` and `brudcast_push` require the
  exact `brudcast_flutter` version.
- **The native SDK version** is `brudcastSdkVersion` in each `android/build.gradle.kts` and `exact:`
  in each `ios/<package>/Package.swift`. All three packages pin the same one, and
  `scripts/check-version.sh` fails when they disagree.

A release that changes only the Dart code, the plugin glue or the packaging keeps the native
version. Moving to a new native version is a change apps notice, so it gets at least a minor
version, and a major one when the native release breaks its API.

## Moving to a new native version

The native release comes first:

1. Release `brudcast-sdk-android` and `brudcast-sdk-ios` at the version, as their `RELEASING.md`
   files describe, and wait until the artifacts are on Maven Central and the tag is on GitHub.
2. On a branch, set `brudcastSdkVersion` in each `android/build.gradle.kts` and `exact:` in each
   `ios/<package>/Package.swift`. Add a line to each `CHANGELOG.md` under `Unreleased`, such as
   "Runs the native SDKs 0.3.0", and merge to `main`.
3. Release the Flutter packages as below.

## Release

1. On a `docs/release-<version>` branch, set the version in:
   - `version:` in each package's `pubspec.yaml`, and the `brudcast_flutter` constraint in
     `brudcast_in_app` and `brudcast_push`;
   - `brudcastFlutterVersion` in `packages/brudcast_flutter/lib/src/version.dart`;
   - the install lines in each package's `README.md`;
   - each `CHANGELOG.md`: move `Unreleased` under the version with today's date, and make sure the
     section names the native SDK version it runs.

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

## Exact constraints

`brudcast_in_app` and `brudcast_push` depend on exactly the same `brudcast_flutter` version, and pub
warns that the constraint is tight. It is tight on purpose: each version pins one native SDK
version, and mixing them could put two native versions in one app. CI fails publishing checks on
errors only, so the warning does not block a release.

## Conventions

- Commits follow [Conventional Commits](https://www.conventionalcommits.org). A change that breaks
  the public API gets a `!` after its type, such as `feat!:`, before 1.0 too.
- Each `CHANGELOG.md` lists what an app using that package gets. How the packages are built and
  released belongs in the pull request and in this file.
