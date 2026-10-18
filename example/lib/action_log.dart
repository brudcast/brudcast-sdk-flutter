import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:flutter/foundation.dart';

/// The actions the SDK handed to the example, newest first, for the account screen to show.
final class ActionLog extends ValueNotifier<List<String>> {
  ActionLog._() : super(const []);

  /// The log.
  static final ActionLog instance = ActionLog._();

  static const int _maxEntries = 20;

  /// Adds an action to the log.
  void record(BrudcastAction action) {
    final origin = switch (action.source.origin) {
      BrudcastActionOrigin.inApp => 'in-app',
      BrudcastActionOrigin.push => 'push',
    };
    final trust = action.verified ? '' : ', unverified';
    final line = '${action.kind.name} ${action.value} ($origin ${action.source.messageId}$trust)';
    value = [line, ...value].take(_maxEntries).toList(growable: false);
  }
}
