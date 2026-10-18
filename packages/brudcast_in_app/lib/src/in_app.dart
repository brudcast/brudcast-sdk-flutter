import 'dart:async';

import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_flutter/module.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'conversions.dart';
import 'heights.dart';
import 'messages.g.dart';
import 'models.dart';

/// In-app messaging. Add [BrudcastInApp.module] to `BrudcastOptions.modules` to run it.
extension BrudcastInAppAccess on BrudcastSdk {
  /// In-app messaging: display control, the message handler and the inbox.
  BrudcastInApp get inApp => BrudcastInApp.instance;
}

/// In-app messaging: triggers, display rules and presentation run natively; this controls them.
final class BrudcastInApp {
  BrudcastInApp._(this._host) : inbox = BrudcastInbox._(_host) {
    InAppFlutterApi.setUp(_Receiver(this));
  }

  /// The module to list in `BrudcastOptions.modules`.
  static const BrudcastModule module = BrudcastModule('in_app');

  /// The in-app module. `Brudcast.inApp` returns it.
  static final BrudcastInApp instance = BrudcastInApp._(InAppHostApi());

  /// Creates an instance over a fake channel, for tests.
  @visibleForTesting
  factory BrudcastInApp.withHostApi(InAppHostApi host) => BrudcastInApp._(host);

  final InAppHostApi _host;
  BrudcastMessageHandler? _messageHandler;

  /// The inbox.
  final BrudcastInbox inbox;

  /// Holds messages back without showing them, such as during checkout or a video. Triggers that
  /// fire meanwhile are kept.
  Future<void> pauseDisplay() async {
    await guardBrudcastCall('pauseDisplay', _host.pauseDisplay);
  }

  /// Shows held messages again after [pauseDisplay].
  Future<void> resumeDisplay() async {
    await guardBrudcastCall('resumeDisplay', _host.resumeDisplay);
  }

  /// Fetches the messages this device should hold now, instead of waiting for the next foreground.
  Future<void> sync() async {
    await guardBrudcastCall('sync', _host.sync);
  }

  /// Sets the handler asked before each message shows. Return [BrudcastMessageDecision.custom] to
  /// draw the message yourself, then report what happened with [reportImpression], [reportClick]
  /// and [reportDismiss]. Pass null to show every message.
  Future<void> setMessageHandler(BrudcastMessageHandler? handler) async {
    _messageHandler = handler;
    await guardBrudcastCall('setMessageHandler', () => _host.setMessageHandlerEnabled(handler != null));
  }

  /// Reports that the app showed a message it draws itself.
  Future<void> reportImpression(String messageId) async {
    await guardBrudcastCall('reportImpression', () => _host.reportImpression(messageId));
  }

  /// Reports a tap on a button of a message the app draws itself. [buttonId] is the design's
  /// button id.
  Future<void> reportClick(String messageId, String buttonId) async {
    await guardBrudcastCall('reportClick', () => _host.reportClick(messageId, buttonId));
  }

  /// Reports that a message the app draws itself was closed without an action.
  Future<void> reportDismiss(String messageId) async {
    await guardBrudcastCall('reportDismiss', () => _host.reportDismiss(messageId));
  }

  Future<BrudcastMessageDecision> _decide(BrudcastInAppMessage message) {
    final handler = _messageHandler;
    if (handler == null) return Future.value(BrudcastMessageDecision.show);
    return runBrudcastHandler('message handler', () => handler(message), BrudcastMessageDecision.show);
  }
}

/// The in-app inbox: messages to read later, kept by the service across devices.
final class BrudcastInbox {
  BrudcastInbox._(this._host);

  final InAppHostApi _host;
  ValueNotifier<int>? _unreadCount;
  StreamSubscription<int>? _unreadSubscription;

  /// The number of unread entries, as last reported by the service. It updates as messages arrive
  /// and are read, on this and the user's other devices.
  ValueListenable<int> get unreadCount {
    final existing = _unreadCount;
    if (existing != null) return existing;
    final created = ValueNotifier<int>(0);
    _unreadCount = created;
    _unreadSubscription = unreadCountChanges().listen(
      (count) => created.value = count,
      onError: (Object error) => BrudcastLog.error('The unread count stream failed: $error'),
    );
    return created;
  }

  /// Opens the native inbox screen, drawn in the accent colour in-app messages use.
  Future<void> present({String title = 'Inbox'}) async {
    await guardBrudcastCall('inbox.present', () => _host.presentInbox(title));
  }

  /// Fetches a page of the inbox, newest first: entries older than [before], at most [limit] of
  /// them, up to 100.
  ///
  /// Completes with a [BrudcastInboxException] when the page cannot be loaded, such as offline or
  /// before `initialize`.
  Future<BrudcastInboxPage> list({DateTime? before, int limit = 20}) async {
    try {
      final page = await _host.listInbox(before?.millisecondsSinceEpoch, limit.clamp(1, 100));
      return BrudcastInboxPage(
        messages: page.messages.map(messageFromPlatform).toList(growable: false),
        unreadCount: page.unreadCount,
        hasMore: page.hasMore,
      );
    } on PlatformException catch (error) {
      throw BrudcastInboxException(error.code, error.message);
    }
  }

  /// Marks an entry read on every device.
  Future<void> markRead(String messageId) async {
    await guardBrudcastCall('inbox.markRead', () => _host.markRead(messageId));
  }

  /// Deletes an entry from the inbox on every device.
  Future<void> delete(String messageId) async {
    await guardBrudcastCall('inbox.delete', () => _host.delete(messageId));
  }

  /// Stops following the unread count, for tests.
  @visibleForTesting
  Future<void> dispose() async {
    await _unreadSubscription?.cancel();
    _unreadSubscription = null;
    _unreadCount = null;
  }
}

/// Makes sure calls from the native side reach Dart, for widgets that need them before the app
/// touches `Brudcast.inApp`.
void ensureInAppReceiver() {
  BrudcastInApp.instance;
}

final class _Receiver implements InAppFlutterApi {
  _Receiver(this._inApp);

  final BrudcastInApp _inApp;

  @override
  Future<PlatformMessageDecision> handleMessage(PlatformInAppMessage message) async =>
      decisionToPlatform(await _inApp._decide(messageFromPlatform(message)));

  @override
  Future<void> inboxMessageHeightChanged(int viewId, double height) async {
    inboxMessageHeightListeners[viewId]?.call(height);
  }
}
