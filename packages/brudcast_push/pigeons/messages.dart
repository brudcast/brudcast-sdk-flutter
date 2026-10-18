import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/com/brudcast/flutter/push/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.brudcast.flutter.push'),
    swiftOut: 'ios/brudcast_push/Sources/brudcast_push/Messages.g.swift',
    dartPackageName: 'brudcast_push',
  ),
)
enum PlatformPushPermission { notDetermined, denied, authorized, provisional }

enum PlatformNotificationDecision { show, suppress }

class PlatformPushNotification {
  PlatformPushNotification({required this.messageId, required this.data});

  String messageId;
  String? campaignId;
  String? applicationId;
  String? title;
  String? body;
  String? imageUrl;
  String? clickUrl;
  Map<String, String> data;
}

@HostApi()
abstract class PushHostApi {
  void setToken(String token);

  @asyncCallback
  PlatformPushPermission requestPermission(bool provisional);

  void setNotificationHandlerEnabled(bool enabled);

  bool handleForegroundMessage(Map<String, String> data, String? title, String? body, String? imageUrl);
}

@FlutterApi()
abstract class PushFlutterApi {
  @asyncCallback
  PlatformNotificationDecision handleNotification(PlatformPushNotification notification);
}

@EventChannelApi()
abstract class PushEvents {
  PlatformPushPermission permissionChanges();
}
