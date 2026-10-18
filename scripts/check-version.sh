#!/usr/bin/env bash
# Checks that everything naming the release version agrees: the three pubspecs, the Dart version
# constant, the packages' constraints on each other, the newest released section of each
# CHANGELOG.md, the native SDK versions pinned in Gradle and Package.swift, and the install lines
# in the READMEs. The Flutter packages share one version with the native SDKs they run, so a
# mismatch anywhere means a release would ship the wrong native code or the wrong docs.
#
# Usage: scripts/check-version.sh [expected-version]
#   With a version, such as the release tag without its v, also checks that everything names it
#   and that each changelog gives its release date.
set -euo pipefail

cd "$(dirname "$0")/.."
packages=(brudcast_flutter brudcast_in_app brudcast_push)
version="$(sed -n 's/^version: *//p' packages/brudcast_flutter/pubspec.yaml)"
expected="${1:-$version}"
mismatch=0

check() {
  if [ "$2" != "$expected" ]; then
    echo "::error::$1 names ${2:-no version}, but the release is $expected"
    mismatch=1
  fi
}

check "packages/brudcast_flutter/lib/src/version.dart" "$(sed -n "s/.*brudcastFlutterVersion = '\(.*\)';/\1/p" packages/brudcast_flutter/lib/src/version.dart)"
for package in "${packages[@]}"; do
  dir="packages/$package"
  check "$dir/pubspec.yaml" "$(sed -n 's/^version: *//p' "$dir/pubspec.yaml")"
  check "The newest released section of $dir/CHANGELOG.md" "$(sed -n 's/^## \[\([0-9][^]]*\)\] - .*/\1/p' "$dir/CHANGELOG.md" | head -n 1)"
  check "The native Android SDK in $dir/android/build.gradle.kts" "$(sed -n 's/^val brudcastSdkVersion = "\(.*\)"/\1/p' "$dir/android/build.gradle.kts")"
  check "The native iOS SDK in $dir/ios/$package/Package.swift" "$(sed -n 's/.*brudcast-sdk-ios.git", exact: "\(.*\)").*/\1/p' "$dir/ios/$package/Package.swift")"
  check "The install line in $dir/README.md" "$(sed -n "s/^  $package: \^\{0,1\}\([0-9][^ ]*\)$/\1/p" "$dir/README.md" | head -n 1)"
done
if [ -n "${1:-}" ]; then
  for package in "${packages[@]}"; do
    if grep -q "^## \[$expected\] - Unreleased" "packages/$package/CHANGELOG.md"; then
      echo "::error::packages/$package/CHANGELOG.md has no release date for $expected"
      mismatch=1
    fi
  done
fi
for package in brudcast_in_app brudcast_push; do
  check "The brudcast_flutter constraint in packages/$package/pubspec.yaml" "$(sed -n 's/^  brudcast_flutter: *//p' "packages/$package/pubspec.yaml")"
done

if [ "$mismatch" -ne 0 ]; then
  echo "Bump them together in the release pull request. See RELEASING.md."
  exit 1
fi
echo "Every package, changelog, native pin and README names $expected"
