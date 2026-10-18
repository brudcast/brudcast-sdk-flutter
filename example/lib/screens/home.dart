import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_in_app/brudcast_in_app.dart';
import 'package:flutter/material.dart';

import '../backend.dart';
import '../router.dart';
import '../session.dart';

/// The landing screen: the inbox bell with its unread badge, the shop, and a welcome message sent
/// through the backend.
class HomeScreen extends StatelessWidget {
  /// Creates the screen.
  const HomeScreen({super.key, required this.session, this.backend});

  /// The signed-in user.
  final SampleSession session;

  /// The backend, when one is configured.
  final SampleBackend? backend;

  Future<void> _sendWelcome(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await backend!.sendWelcome(session.externalId!);
      messenger.showSnackBar(const SnackBar(content: Text('Welcome sent; it shows in a moment')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Home'),
      actions: [
        ValueListenableBuilder<int>(
          valueListenable: Brudcast.inApp.inbox.unreadCount,
          builder: (context, unread, _) => IconButton(
            key: const Key('inbox'),
            tooltip: 'Inbox, $unread unread',
            onPressed: () => Navigator.of(context).pushNamed(Routes.inbox),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Account',
          onPressed: () => Navigator.of(context).pushNamed(Routes.account),
          icon: const Icon(Icons.person_outline),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Hello${session.email == null ? '' : ', ${session.email}'}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('shop'),
          onPressed: () => Navigator.of(context).pushNamed(Routes.shop),
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Shop'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Brudcast.inApp.inbox.present(title: 'Inbox'),
          icon: const Icon(Icons.inbox_outlined),
          label: const Text('Open the native inbox'),
        ),
        if (backend != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _sendWelcome(context),
            icon: const Icon(Icons.waving_hand_outlined),
            label: const Text('Send me a welcome'),
          ),
        ],
      ],
    ),
  );
}
