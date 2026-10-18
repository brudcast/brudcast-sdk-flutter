import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// How a message is drawn.
enum BrudcastMessageFormat {
  /// A card over the app, with a dimmed overlay.
  modal,

  /// A strip at the top or bottom of the screen.
  banner,

  /// The whole screen.
  fullscreen,

  /// Only in the inbox; it never shows on its own.
  inboxOnly,
}

/// A message as the app sees it, in the message handler and the inbox.
@immutable
final class BrudcastInAppMessage {
  /// Creates a message. The SDK creates them; apps create them in tests.
  const BrudcastInAppMessage({
    required this.id,
    this.campaignId,
    required this.format,
    this.isTest = false,
    required this.title,
    required this.preview,
    this.thumbnailUrl,
    this.isRead = false,
    required this.createdAt,
    required this.design,
  });

  /// The message id, which the report calls take.
  final String id;

  /// The campaign that sent it, or null for a transactional message.
  final String? campaignId;

  /// How it is drawn.
  final BrudcastMessageFormat format;

  /// Whether it is a test send from the dashboard.
  final bool isTest;

  /// The inbox title, or the design's title.
  final String title;

  /// The inbox preview, or the design's body text.
  final String preview;

  /// The inbox thumbnail, or the design's first image.
  final Uri? thumbnailUrl;

  /// Whether the user has read it in the inbox.
  final bool isRead;

  /// When it was sent.
  final DateTime createdAt;

  /// The design document as JSON, for apps that draw messages themselves.
  final String design;

  /// The design document decoded, or an empty map when it is not a JSON object.
  Map<String, Object?> get designDocument {
    try {
      final decoded = jsonDecode(design);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  /// A copy of the message marked read.
  BrudcastInAppMessage markedRead() => BrudcastInAppMessage(
    id: id,
    campaignId: campaignId,
    format: format,
    isTest: isTest,
    title: title,
    preview: preview,
    thumbnailUrl: thumbnailUrl,
    isRead: true,
    createdAt: createdAt,
    design: design,
  );

  @override
  bool operator ==(Object other) =>
      other is BrudcastInAppMessage &&
      other.id == id &&
      other.campaignId == campaignId &&
      other.format == format &&
      other.isTest == isTest &&
      other.title == title &&
      other.preview == preview &&
      other.thumbnailUrl == thumbnailUrl &&
      other.isRead == isRead &&
      other.createdAt == createdAt &&
      other.design == design;

  @override
  int get hashCode =>
      Object.hash(id, campaignId, format, isTest, title, preview, thumbnailUrl, isRead, createdAt, design);

  @override
  String toString() =>
      'BrudcastInAppMessage(id: $id, campaignId: $campaignId, format: $format, title: $title, isRead: $isRead)';
}

/// One page of the inbox, newest first.
@immutable
final class BrudcastInboxPage {
  /// Creates a page.
  const BrudcastInboxPage({required this.messages, required this.unreadCount, required this.hasMore});

  /// The entries on this page.
  final List<BrudcastInAppMessage> messages;

  /// The number of unread entries in the whole inbox.
  final int unreadCount;

  /// Whether older entries remain.
  final bool hasMore;

  @override
  bool operator ==(Object other) =>
      other is BrudcastInboxPage &&
      listEquals(other.messages, messages) &&
      other.unreadCount == unreadCount &&
      other.hasMore == hasMore;

  @override
  int get hashCode => Object.hash(Object.hashAll(messages), unreadCount, hasMore);

  @override
  String toString() => 'BrudcastInboxPage(messages: ${messages.length}, unreadCount: $unreadCount, hasMore: $hasMore)';
}

/// Why the inbox could not be loaded.
final class BrudcastInboxException implements Exception {
  /// Creates an exception.
  const BrudcastInboxException(this.code, this.message);

  /// The service's error code, such as `not_initialized`, or `inbox_failed`.
  final String code;

  /// What went wrong.
  final String? message;

  @override
  String toString() => 'BrudcastInboxException($code: $message)';
}

/// What the message handler wants done with a message about to show.
enum BrudcastMessageDecision {
  /// Show it with the standard renderer.
  show,

  /// Do not show it for this trigger.
  suppress,

  /// Do not show it now; the next trigger may show it.
  defer,

  /// The app draws it, and reports impression, click and dismiss itself.
  custom,
}

/// Decides what happens to a message about to show. It has two seconds to answer, after which the
/// message shows.
typedef BrudcastMessageHandler = FutureOr<BrudcastMessageDecision> Function(BrudcastInAppMessage message);
