import 'package:flutter/material.dart';

/// The example's look.
abstract final class SampleTheme {
  /// The example's primary blue, also passed to the SDK for buttons in messages.
  static const Color primary = Color(0xFF365AED);

  /// The light theme.
  static final ThemeData light = ThemeData(colorSchemeSeed: primary, useMaterial3: true);

  /// The dark theme.
  static final ThemeData dark = ThemeData(colorSchemeSeed: primary, brightness: Brightness.dark, useMaterial3: true);
}
