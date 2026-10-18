import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_push/brudcast_push.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Runs in a separate isolate when a data message arrives with the app in the background. The
/// Brudcast plugin is not attached there, so only pure Dart checks are safe.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  if (BrudcastPush.isBrudcastNotification(message.data)) return;
  debugPrint('A message from another sender arrived in the background: ${message.messageId}');
}

/// Connects `firebase_messaging` to Brudcast: the token, token refreshes, and foreground messages,
/// which Android does not show by itself. Taps need nothing here; the SDK records them natively.
Future<void> setUpPush() async {
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase is not configured, so push tokens are not registered: $error');
    return;
  }
  final messaging = FirebaseMessaging.instance;
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

  final token = await messaging.getToken();
  if (token != null) await Brudcast.push.setToken(token);
  messaging.onTokenRefresh.listen(Brudcast.push.setToken);

  FirebaseMessaging.onMessage.listen((message) async {
    final notification = message.notification;
    await Brudcast.push.handleForegroundMessage(
      message.data,
      title: notification?.title,
      body: notification?.body,
      imageUrl: notification?.android?.imageUrl,
    );
  });
}
