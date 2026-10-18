import 'package:brudcast_flutter/brudcast_flutter.dart';

/// The example's settings, passed with `--dart-define-from-file=config/<name>.json`.
abstract final class SampleConfig {
  /// The publishable key of an in-app application in the dashboard.
  static const String publishableKey = String.fromEnvironment('BRUDCAST_PUBLISHABLE_KEY');

  /// `production`, `staging`, `uat`, `development` or `local`.
  static const String environmentName = String.fromEnvironment('BRUDCAST_ENVIRONMENT', defaultValue: 'production');

  /// The port of a local in-app delivery service.
  static const int localPort = int.fromEnvironment('BRUDCAST_LOCAL_PORT', defaultValue: 8191);

  /// The app's own backend, which signs users in. Empty to sign in with a pasted user hash.
  static const String sampleBackendUrl = String.fromEnvironment('SAMPLE_BACKEND_URL');

  /// Whether the app has a Firebase configuration, so push tokens can be read.
  static const bool firebaseEnabled = bool.fromEnvironment('FIREBASE_ENABLED');

  /// The environment [environmentName] names.
  static BrudcastEnvironment get environment => switch (environmentName.toLowerCase()) {
    'staging' => BrudcastEnvironment.staging,
    'uat' => BrudcastEnvironment.uat,
    'development' => BrudcastEnvironment.development,
    'local' => const BrudcastEnvironment.local(port: localPort),
    _ => BrudcastEnvironment.production,
  };
}
