import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/com/brudcast/flutter/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.brudcast.flutter'),
    swiftOut: 'ios/brudcast_flutter/Sources/brudcast_flutter/Messages.g.swift',
    dartPackageName: 'brudcast_flutter',
  ),
)
enum PlatformEnvironmentKind { production, staging, uat, development, local, custom }

class PlatformEnvironment {
  PlatformEnvironment({required this.kind});

  PlatformEnvironmentKind kind;
  String? androidHost;
  int? port;
  String? baseUrl;
}

enum PlatformLogLevel { verbose, debug, info, warning, error, none }

enum PlatformAppearance { system, light, dark }

class PlatformOptions {
  PlatformOptions({
    required this.environment,
    required this.logLevel,
    required this.appearance,
    required this.modules,
    required this.wrapperVersion,
  });

  PlatformEnvironment environment;
  PlatformLogLevel logLevel;
  PlatformAppearance appearance;
  int? accentColor;
  List<String> modules;
  String? appGroupIdentifier;
  String wrapperVersion;
}

class PlatformTraits {
  String? email;
  String? phone;
  String? firstName;
  String? lastName;
  String? language;
  String? timezone;
}

enum PlatformActionKind { deeplink, url, customEvent }

enum PlatformActionSource { inApp, push }

class PlatformAction {
  PlatformAction({
    required this.kind,
    required this.value,
    required this.opensInApp,
    required this.source,
    required this.messageId,
    required this.verified,
  });

  PlatformActionKind kind;
  String value;
  bool opensInApp;
  PlatformActionSource source;
  String messageId;
  String? buttonId;
  bool verified;
}

enum PlatformActionResult { handled, useDefault }

@HostApi()
abstract class BrudcastHostApi {
  void initialize(String publishableKey, PlatformOptions options);

  void identify(String externalId, String? userHash, PlatformTraits? traits);

  void reset();

  void track(String name, Map<String, Object?> properties);

  void screen(String name, Map<String, Object?> properties);

  void setOptedOut(bool optedOut);

  void setTrackingEnabled(bool enabled);

  void flush();

  void setActionHandlerEnabled(bool enabled);

  String? deviceId();
}

@FlutterApi()
abstract class BrudcastFlutterApi {
  @asyncCallback
  PlatformActionResult handleAction(PlatformAction action);
}
