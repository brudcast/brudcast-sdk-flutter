# Example

Run the module, hold messages back during checkout, and build an inbox screen in Flutter:

```dart
import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_in_app/brudcast_in_app.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Brudcast.initialize('bpk_...', const BrudcastOptions(modules: [BrudcastInApp.module]));
  runApp(const MaterialApp(home: InboxScreen()));
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final controller = InboxController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Inbox')),
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              children: [
                for (final message in controller.messages)
                  ListTile(
                    title: Text(message.title),
                    subtitle: Text(message.preview),
                    onTap: () {
                      controller.markRead(message);
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => Scaffold(body: BrudcastInboxMessage(message: message, expand: true)),
                      ));
                    },
                  ),
              ],
            ),
          ),
        ),
      );
}

Future<void> checkout() async {
  await Brudcast.inApp.pauseDisplay();
  await Brudcast.track('checkout_started');
}
```

A complete app is in the
[repository's `example`](https://github.com/brudcast/brudcast-sdk-flutter/tree/main/example).
