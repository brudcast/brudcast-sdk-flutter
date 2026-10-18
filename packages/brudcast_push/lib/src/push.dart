import 'dart:async';

import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_flutter/module.dart';
import 'package:flutter/foundation.dart';

import 'messages.g.dart';
import 'models.dart';

/// Push notifications. Add [BrudcastPush.module] to `BrudcastOptions.modules` to run it.
extension BrudcastPushAccess on BrudcastSdk {
  /// Push notifications: permission, the token and the notification handler.
  BrudcastPush get push => BrudcastPush.instance;
}

/// Push notifications. Brudcast sends through FCM, so pass the FCM token from `firebase_messaging`
/// to [setToken]. Taps are recorded natively, with no Dart code.
final class BrudcastPush {
  BrudcastPush._(this._host, [this._platform]);

  /// The module to list in `BrudcastOptions.modules`.
  static const BrudcastModule module = BrudcastModule('push');

  /// The push module. `Brudcast.push` returns it.
  static final BrudcastPush instance = BrudcastPush._(PushHostApi());

  /// Creates an instance over a fake channel, for tests.
  @visibleForTesting
  factory BrudcastPush.withHostApi(PushHostApi host, {TargetPlatform? platform}) => BrudcastPush._(host, platform);

  final PushHostApi _host;
  final TargetPlatform? _platform;
  BrudcastNotificationHandler? _notificationHandler;
  ValueNotifier<BrudcastPushPermission>? _permissionStatus;

  /// The permission status, kept current as the user changes it in settings.
  ValueListenable<BrudcastPushPermission> get permissionStatus {
    final existing = _permissionStatus;
    if (existing != null) return existing;
    final created = ValueNotifier(BrudcastPushPermission.notDetermined);
    _permissionStatus = created;
    permissionChanges().listen(
      (status) => created.value = _permission(status),
      onError: (Object error) => BrudcastLog.error('The permission stream failed: $error'),
    );
    return created;
  }

  /// Stores the FCM registration token and registers it for this user. Pass the token from
  /// `FirebaseMessaging.instance.getToken()`, and every token from `onTokenRefresh`.
  Future<void> setToken(String token) async {
    await guardBrudcastCall('setToken', () => _host.setToken(token));
  }

  /// Asks the user for permission to show notifications, on Android 13 and later and on iOS. On
  /// iOS it then registers with APNs. [provisional] asks iOS for quiet delivery without a prompt.
  ///
  /// Returns the status after the user answered.
  Future<BrudcastPushPermission> requestPermission({bool provisional = false}) async {
    final status = await guardBrudcastCall('requestPermission', () => _host.requestPermission(provisional));
    return status == null ? BrudcastPushPermission.notDetermined : _permission(status);
  }

  /// Sets the handler asked when a Brudcast notification arrives while the app is open. Pass null
  /// to show every notification.
  ///
  /// On iOS, when `firebase_messaging` is installed it decides how a foreground notification is
  /// presented, from `setForegroundNotificationPresentationOptions`, and this handler is not asked.
  Future<void> setNotificationHandler(BrudcastNotificationHandler? handler) async {
    _notificationHandler = handler;
    PushFlutterApi.setUp(handler == null ? null : _Receiver(this));
    await guardBrudcastCall('setNotificationHandler', () => _host.setNotificationHandlerEnabled(handler != null));
  }

  /// Hands a message `firebase_messaging` delivered in the foreground to the SDK. On Android,
  /// `firebase_messaging` does not show foreground notifications, so call this from
  /// `FirebaseMessaging.onMessage` with the message's `data` and notification fields: the SDK
  /// records it, asks the notification handler and shows it. On iOS it does nothing, since the
  /// system shows the notification, so call it on both platforms.
  ///
  /// Returns true when the message is from Brudcast, so the app should not show it itself.
  Future<bool> handleForegroundMessage(
    Map<String, Object?> data, {
    String? title,
    String? body,
    String? imageUrl,
  }) async {
    final strings = {
      for (final entry in data.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };
    if (!isBrudcastNotification(strings)) return false;
    if ((_platform ?? defaultTargetPlatform) != TargetPlatform.android) return true;
    final handled = await guardBrudcastCall(
      'handleForegroundMessage',
      () => _host.handleForegroundMessage(strings, title, body, imageUrl),
    );
    return handled ?? true;
  }

  /// Tells whether message data came from Brudcast: it carries a Brudcast message id. Pure Dart, so
  /// it also works in `firebase_messaging`'s background handler, where the plugin is not attached.
  static bool isBrudcastNotification(Map<String, Object?> data) {
    final messageId = data[BrudcastPushKeys.messageId];
    return messageId is String && messageId.isNotEmpty;
  }

  Future<BrudcastNotificationDecision> _decide(BrudcastPushNotification notification) {
    final handler = _notificationHandler;
    if (handler == null) return Future.value(BrudcastNotificationDecision.show);
    return runBrudcastHandler('notification handler', () => handler(notification), BrudcastNotificationDecision.show);
  }

  static BrudcastPushPermission _permission(PlatformPushPermission status) => switch (status) {
    PlatformPushPermission.notDetermined => BrudcastPushPermission.notDetermined,
    PlatformPushPermission.denied => BrudcastPushPermission.denied,
    PlatformPushPermission.authorized => BrudcastPushPermission.authorized,
    PlatformPushPermission.provisional => BrudcastPushPermission.provisional,
  };
}

final class _Receiver implements PushFlutterApi {
  _Receiver(this._push);

  final BrudcastPush _push;

  @override
  Future<PlatformNotificationDecision> handleNotification(PlatformPushNotification notification) async {
    final decision = await _push._decide(
      BrudcastPushNotification(
        messageId: notification.messageId,
        campaignId: notification.campaignId,
        applicationId: notification.applicationId,
        title: notification.title,
        body: notification.body,
        imageUrl: notification.imageUrl,
        clickUrl: notification.clickUrl,
        data: notification.data,
      ),
    );
    return switch (decision) {
      BrudcastNotificationDecision.show => PlatformNotificationDecision.show,
      BrudcastNotificationDecision.suppress => PlatformNotificationDecision.suppress,
    };
  }
}
