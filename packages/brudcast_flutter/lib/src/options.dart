import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// The Brudcast environment the SDK talks to.
@immutable
final class BrudcastEnvironment {
  const BrudcastEnvironment._(this.name) : port = null, androidHost = null, baseUrl = null;

  /// The production service.
  static const BrudcastEnvironment production = BrudcastEnvironment._('production');

  /// The staging service.
  static const BrudcastEnvironment staging = BrudcastEnvironment._('staging');

  /// The UAT service.
  static const BrudcastEnvironment uat = BrudcastEnvironment._('uat');

  /// The development service.
  static const BrudcastEnvironment development = BrudcastEnvironment._('development');

  /// The service on the development machine: `localhost` from the iOS simulator, and
  /// [androidHost], `10.0.2.2` by default, from the Android emulator.
  const BrudcastEnvironment.local({int this.port = 8191, String this.androidHost = '10.0.2.2'})
    : name = 'local',
      baseUrl = null;

  /// Any other deployment, by the base URL of its SDK API, ending in `/sdk/v1`.
  BrudcastEnvironment.custom(Uri baseUrl)
    : name = 'custom',
      port = null,
      androidHost = null,
      baseUrl = baseUrl.toString();

  /// Which environment this is: `production`, `staging`, `uat`, `development`, `local` or
  /// `custom`.
  final String name;

  /// The port of a [BrudcastEnvironment.local] service.
  final int? port;

  /// The host the Android emulator reaches a [BrudcastEnvironment.local] service on.
  final String? androidHost;

  /// The base URL of a [BrudcastEnvironment.custom] service.
  final String? baseUrl;

  @override
  bool operator ==(Object other) =>
      other is BrudcastEnvironment &&
      other.name == name &&
      other.port == port &&
      other.androidHost == androidHost &&
      other.baseUrl == baseUrl;

  @override
  int get hashCode => Object.hash(name, port, androidHost, baseUrl);

  @override
  String toString() => 'BrudcastEnvironment($name${baseUrl == null ? '' : ', $baseUrl'})';
}

/// How much the SDK logs.
enum BrudcastLogLevel {
  /// Everything, including each request.
  verbose,

  /// Decisions the SDK makes, such as why a message did not show.
  debug,

  /// Sessions, syncs and registrations.
  info,

  /// Problems the app should fix, such as a handler that did not answer.
  warning,

  /// Failures, such as a refused key or user hash.
  error,

  /// Nothing.
  none,
}

/// Which appearance in-app messages use.
enum BrudcastAppearance {
  /// Follow the device's light or dark setting.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// A feature module the SDK runs, such as in-app messaging or push. Add `BrudcastInApp.module` from
/// `brudcast_in_app` and `BrudcastPush.module` from `brudcast_push` to [BrudcastOptions.modules].
@immutable
final class BrudcastModule {
  /// Names a module. The package that provides the module creates it.
  const BrudcastModule(this.name);

  /// The module's name, such as `in_app` or `push`.
  final String name;

  @override
  bool operator ==(Object other) => other is BrudcastModule && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'BrudcastModule($name)';
}

/// Configuration passed to `Brudcast.initialize`.
@immutable
final class BrudcastOptions {
  /// Creates options. Every field has a default, so `const BrudcastOptions()` runs the core alone
  /// against production.
  const BrudcastOptions({
    this.environment = BrudcastEnvironment.production,
    this.logLevel = BrudcastLogLevel.warning,
    this.appearance = BrudcastAppearance.system,
    this.accentColor,
    this.modules = const [],
    this.appGroupIdentifier,
  });

  /// The environment to talk to.
  final BrudcastEnvironment environment;

  /// The lowest level that is logged, natively and in Dart.
  final BrudcastLogLevel logLevel;

  /// Light, dark, or following the device, for in-app messages and the inbox.
  final BrudcastAppearance appearance;

  /// The default colour of buttons in messages. When null, the Android theme's primary colour or
  /// the iOS key window's tint is used.
  final Color? accentColor;

  /// The modules to run, such as `BrudcastInApp.module` and `BrudcastPush.module`.
  final List<BrudcastModule> modules;

  /// iOS only: the App Group shared with a notification service extension, so the extension can
  /// record `push_received` for the app to send. Ignored on Android.
  final String? appGroupIdentifier;

  @override
  bool operator ==(Object other) =>
      other is BrudcastOptions &&
      other.environment == environment &&
      other.logLevel == logLevel &&
      other.appearance == appearance &&
      other.accentColor == accentColor &&
      listEquals(other.modules, modules) &&
      other.appGroupIdentifier == appGroupIdentifier;

  @override
  int get hashCode =>
      Object.hash(environment, logLevel, appearance, accentColor, Object.hashAll(modules), appGroupIdentifier);

  @override
  String toString() =>
      'BrudcastOptions(environment: $environment, logLevel: $logLevel, appearance: $appearance, accentColor: $accentColor, modules: $modules, appGroupIdentifier: $appGroupIdentifier)';
}

/// Optional traits sent with `identify`. Brudcast uses them to fill a new contact; they never
/// overwrite values a contact already has.
@immutable
final class BrudcastTraits {
  /// Creates traits.
  const BrudcastTraits({this.email, this.phone, this.firstName, this.lastName, this.language, this.timezone});

  /// The user's email address.
  final String? email;

  /// The user's phone number, in E.164 form such as `+2348012345678`.
  final String? phone;

  /// The user's first name.
  final String? firstName;

  /// The user's last name.
  final String? lastName;

  /// The user's language, as a BCP 47 tag such as `en` or `fr-CA`.
  final String? language;

  /// The user's time zone, as an IANA name such as `Africa/Lagos`.
  final String? timezone;

  @override
  bool operator ==(Object other) =>
      other is BrudcastTraits &&
      other.email == email &&
      other.phone == phone &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.language == language &&
      other.timezone == timezone;

  @override
  int get hashCode => Object.hash(email, phone, firstName, lastName, language, timezone);

  @override
  String toString() =>
      'BrudcastTraits(email: $email, phone: $phone, firstName: $firstName, lastName: $lastName, language: $language, timezone: $timezone)';
}
