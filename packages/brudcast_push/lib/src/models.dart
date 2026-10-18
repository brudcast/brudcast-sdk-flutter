import 'dart:async';

import 'package:flutter/foundation.dart';

/// Whether the app may show notifications.
enum BrudcastPushPermission {
  /// The user has not been asked yet.
  notDetermined,

  /// The user refused, or turned notifications off.
  denied,

  /// The user allowed notifications.
  authorized,

  /// iOS only: notifications are delivered quietly, without having asked.
  provisional,
}

/// What the notification handler wants done with a Brudcast notification that arrives while the
/// app is open.
enum BrudcastNotificationDecision {
  /// Show it.
  show,

  /// Do not show it.
  suppress,
}

/// The data keys Brudcast adds to every push notification.
abstract final class BrudcastPushKeys {
  /// The Brudcast push message id. A payload without it is not from Brudcast.
  static const String messageId = 'bc_mid';

  /// The campaign id, or the transactional id.
  static const String campaignId = 'bc_cid';

  /// The push application id.
  static const String applicationId = 'bc_app';

  /// The link opened on tap, through the action handler.
  static const String clickUrl = 'click_url';
}

/// A push notification Brudcast sent.
@immutable
final class BrudcastPushNotification {
  /// Creates a notification. The SDK creates them; apps create them in tests.
  const BrudcastPushNotification({
    required this.messageId,
    this.campaignId,
    this.applicationId,
    this.title,
    this.body,
    this.imageUrl,
    this.clickUrl,
    this.data = const {},
  });

  /// The Brudcast push message id.
  final String messageId;

  /// The campaign id, or the transactional id.
  final String? campaignId;

  /// The push application id.
  final String? applicationId;

  /// The title.
  final String? title;

  /// The body.
  final String? body;

  /// The image, on Android.
  final String? imageUrl;

  /// The link opened on tap.
  final String? clickUrl;

  /// The custom data the campaign carried, without the Brudcast keys.
  final Map<String, String> data;

  @override
  bool operator ==(Object other) =>
      other is BrudcastPushNotification &&
      other.messageId == messageId &&
      other.campaignId == campaignId &&
      other.applicationId == applicationId &&
      other.title == title &&
      other.body == body &&
      other.imageUrl == imageUrl &&
      other.clickUrl == clickUrl &&
      mapEquals(other.data, data);

  @override
  int get hashCode => Object.hash(
    messageId,
    campaignId,
    applicationId,
    title,
    body,
    imageUrl,
    clickUrl,
    Object.hashAllUnordered(data.entries.map((entry) => Object.hash(entry.key, entry.value))),
  );

  @override
  String toString() =>
      'BrudcastPushNotification(messageId: $messageId, campaignId: $campaignId, title: $title, clickUrl: $clickUrl)';
}

/// Decides whether a notification arriving while the app is open shows. It has two seconds to
/// answer, after which the notification shows.
typedef BrudcastNotificationHandler =
    FutureOr<BrudcastNotificationDecision> Function(BrudcastPushNotification notification);
