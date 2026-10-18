import 'dart:async';

import 'package:flutter/foundation.dart';

/// What an action asks the app to do.
enum BrudcastActionKind {
  /// Open a link into the app.
  deeplink,

  /// Open a web page.
  url,

  /// Handle a custom event, named by the action's value.
  customEvent,
}

/// Where an action came from.
enum BrudcastActionOrigin {
  /// A button of an in-app message.
  inApp,

  /// A tap on a push notification.
  push,
}

/// The message, and for in-app messages the button, an action came from.
@immutable
final class BrudcastActionSource {
  /// Creates a source.
  const BrudcastActionSource({required this.origin, required this.messageId, this.buttonId});

  /// An in-app message or a push notification.
  final BrudcastActionOrigin origin;

  /// The message id.
  final String messageId;

  /// The tapped button of an in-app message.
  final String? buttonId;

  @override
  bool operator ==(Object other) =>
      other is BrudcastActionSource &&
      other.origin == origin &&
      other.messageId == messageId &&
      other.buttonId == buttonId;

  @override
  int get hashCode => Object.hash(origin, messageId, buttonId);

  @override
  String toString() => 'BrudcastActionSource(origin: $origin, messageId: $messageId, buttonId: $buttonId)';
}

/// Something a message asked the app to do: open a deep link or a URL, or handle a custom event.
@immutable
final class BrudcastAction {
  /// Creates an action.
  const BrudcastAction({
    required this.kind,
    required this.value,
    this.opensInApp = false,
    required this.source,
    this.verified = true,
  });

  /// What to do.
  final BrudcastActionKind kind;

  /// The link, or the custom event's name.
  final String value;

  /// Whether a web link should open inside the app rather than in the browser.
  final bool opensInApp;

  /// The message and button the action came from.
  final BrudcastActionSource source;

  /// False on Android when the action came from a push tap the SDK cannot prove it created, which
  /// another app could forge. Check it before routing a deep link to a private screen.
  final bool verified;

  @override
  bool operator ==(Object other) =>
      other is BrudcastAction &&
      other.kind == kind &&
      other.value == value &&
      other.opensInApp == opensInApp &&
      other.source == source &&
      other.verified == verified;

  @override
  int get hashCode => Object.hash(kind, value, opensInApp, source, verified);

  @override
  String toString() =>
      'BrudcastAction(kind: $kind, value: $value, opensInApp: $opensInApp, source: $source, verified: $verified)';
}

/// What the action handler did with an action.
enum BrudcastActionResult {
  /// The app handled it; the SDK does nothing more.
  handled,

  /// The SDK runs its default: it opens the link, and does nothing for a custom event.
  useDefault,
}

/// Decides what to do with an action before the default behaviour. It has two seconds to answer,
/// after which the default runs.
typedef BrudcastActionHandler = FutureOr<BrudcastActionResult> Function(BrudcastAction action);
