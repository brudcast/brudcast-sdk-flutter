# Example

Start the SDK before `runApp`, identify the user at sign-in with the hash your server computes, and
record what the user does:

```dart
import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Brudcast.setActionHandler((action) {
    if (action.kind == BrudcastActionKind.deeplink && action.value.startsWith('myapp:')) {
      navigatorKey.currentState?.pushNamed(Uri.parse(action.value).path);
      return BrudcastActionResult.handled;
    }
    return BrudcastActionResult.useDefault;
  });
  await Brudcast.initialize('bpk_...');
  runApp(MaterialApp(navigatorKey: navigatorKey, home: const Placeholder()));
}

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> signedIn(String userId, String userHash, String email) async {
  await Brudcast.identify(userId, userHash: userHash, traits: BrudcastTraits(email: email));
  await Brudcast.track('signed_in', {'method': 'email'});
}

Future<void> signedOut() => Brudcast.reset();
```

A complete app, with sign-in through a backend, a shop, an inbox and push, is in the
[repository's `example`](https://github.com/brudcast/brudcast-sdk-flutter/tree/main/example).
