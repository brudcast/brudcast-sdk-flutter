import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_in_app/brudcast_in_app.dart';
import 'package:brudcast_push/brudcast_push.dart';
import 'package:flutter/material.dart';

import '../action_log.dart';
import '../router.dart';
import '../session.dart';

/// Notification permission, display controls, the action log, developer tools for any event or
/// screen, and sign-out.
class AccountScreen extends StatefulWidget {
  /// Creates the screen.
  const AccountScreen({super.key, required this.session});

  /// The signed-in user.
  final SampleSession session;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _name = TextEditingController();
  bool _paused = false;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    Brudcast.deviceId.then((id) {
      if (mounted) setState(() => _deviceId = id);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _togglePause(bool paused) async {
    setState(() => _paused = paused);
    await (paused ? Brudcast.inApp.pauseDisplay() : Brudcast.inApp.resumeDisplay());
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await widget.session.signOut();
    await navigator.pushNamedAndRemoveUntil(Routes.signIn, (_) => false);
  }

  void _send(bool asScreen) {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    asScreen ? Brudcast.screen(name) : Brudcast.track(name);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${asScreen ? 'Screen' : 'Event'} $name sent')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account')),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(title: const Text('Signed in as'), subtitle: Text(widget.session.externalId ?? 'nobody')),
        ListTile(title: const Text('Device id'), subtitle: Text(_deviceId ?? '…')),
        ValueListenableBuilder<BrudcastPushPermission>(
          valueListenable: Brudcast.push.permissionStatus,
          builder: (context, status, _) => ListTile(
            title: const Text('Notifications'),
            subtitle: Text(status.name),
            trailing: status == BrudcastPushPermission.authorized
                ? null
                : TextButton(onPressed: () => Brudcast.push.requestPermission(), child: const Text('Allow')),
          ),
        ),
        SwitchListTile(title: const Text('Pause in-app messages'), value: _paused, onChanged: _togglePause),
        ListTile(
          title: const Text('Sync messages now'),
          trailing: const Icon(Icons.sync),
          onTap: () => Brudcast.inApp.sync(),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Event or screen name'),
          ),
        ),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => _send(false), child: const Text('Track event')),
            TextButton(onPressed: () => _send(true), child: const Text('Record screen')),
          ],
        ),
        const Divider(),
        const ListTile(title: Text('Actions')),
        ValueListenableBuilder<List<String>>(
          valueListenable: ActionLog.instance,
          builder: (context, lines, _) => Column(
            children: lines.isEmpty
                ? [const ListTile(dense: true, title: Text('No actions yet'))]
                : [for (final line in lines) ListTile(dense: true, title: Text(line))],
          ),
        ),
        const Divider(),
        ListTile(
          key: const Key('signOut'),
          title: Text('Sign out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          onTap: _signOut,
        ),
      ],
    ),
  );
}
