import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/com/brudcast/flutter/inapp/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.brudcast.flutter.inapp'),
    swiftOut: 'ios/brudcast_in_app/Sources/brudcast_in_app/Messages.g.swift',
    dartPackageName: 'brudcast_in_app',
  ),
)
enum PlatformMessageFormat { modal, banner, fullscreen, inboxOnly }

class PlatformInAppMessage {
  PlatformInAppMessage({
    required this.id,
    required this.format,
    required this.isTest,
    required this.title,
    required this.preview,
    required this.isRead,
    required this.createdAtMillis,
    required this.design,
  });

  String id;
  String? campaignId;
  PlatformMessageFormat format;
  bool isTest;
  String title;
  String preview;
  String? thumbnailUrl;
  bool isRead;
  int createdAtMillis;
  String design;
}

class PlatformInboxPage {
  PlatformInboxPage({required this.messages, required this.unreadCount, required this.hasMore});

  List<PlatformInAppMessage> messages;
  int unreadCount;
  bool hasMore;
}

enum PlatformMessageDecision { show, suppress, deferred, custom }

@HostApi()
abstract class InAppHostApi {
  void pauseDisplay();

  void resumeDisplay();

  void sync();

  void setMessageHandlerEnabled(bool enabled);

  void reportImpression(String messageId);

  void reportClick(String messageId, String buttonId);

  void reportDismiss(String messageId);

  void presentInbox(String title);

  @asyncCallback
  PlatformInboxPage listInbox(int? beforeMillis, int limit);

  void markRead(String messageId);

  void delete(String messageId);
}

@FlutterApi()
abstract class InAppFlutterApi {
  @asyncCallback
  PlatformMessageDecision handleMessage(PlatformInAppMessage message);

  @asyncCallback
  void inboxMessageHeightChanged(int viewId, double height);
}

@EventChannelApi()
abstract class InAppEvents {
  int unreadCountChanges();
}
