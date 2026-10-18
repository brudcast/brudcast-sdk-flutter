# Example

Connect `firebase_messaging` to Brudcast. Taps need no code; the SDK records them natively.

```dart
import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_push/brudcast_push.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Brudcast.initialize('bpk_...', const BrudcastOptions(modules: [BrudcastPush.module]));

  await Firebase.initializeApp();
  final messaging = FirebaseMessaging.instance;
  final token = await messaging.getToken();
  if (token != null) await Brudcast.push.setToken(token);
  messaging.onTokenRefresh.listen(Brudcast.push.setToken);

  FirebaseMessaging.onMessage.listen((message) {
    Brudcast.push.handleForegroundMessage(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
      imageUrl: message.notification?.android?.imageUrl,
    );
  });

  runApp(const MaterialApp(home: Placeholder()));
}

Future<void> askForNotifications() async {
  final status = await Brudcast.push.requestPermission();
  if (status == BrudcastPushPermission.denied) {
    debugPrint('Notifications are off; offer a link to settings');
  }
}
```

A complete app is in the
[repository's `example`](https://github.com/brudcast/brudcast-sdk-flutter/tree/main/example).
