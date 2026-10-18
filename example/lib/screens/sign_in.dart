import 'package:flutter/material.dart';

import '../backend.dart';
import '../router.dart';
import '../session.dart';

/// Signs a user in through the backend, which computes the user hash, or with a pasted hash when
/// no backend is configured.
class SignInScreen extends StatefulWidget {
  /// Creates the screen.
  const SignInScreen({super.key, required this.session, this.backend});

  /// The session to sign in to.
  final SampleSession session;

  /// The backend, when one is configured.
  final SampleBackend? backend;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _userId = TextEditingController();
  final _email = TextEditingController();
  final _hash = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _userId.dispose();
    _email.dispose();
    _hash.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final userId = _userId.text.trim();
    final email = _email.text.trim().isEmpty ? null : _email.text.trim();
    if (userId.isEmpty) return setState(() => _error = 'Enter a user id');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final backend = widget.backend;
      if (backend == null) {
        await widget.session.signIn(externalId: userId, userHash: _hash.text.trim(), email: email);
      } else {
        final signedIn = await backend.login(userId, email);
        await widget.session.signIn(
          externalId: signedIn.externalId,
          userHash: signedIn.userHash,
          email: signedIn.email,
        );
      }
      if (mounted) await Navigator.of(context).pushReplacementNamed(Routes.home);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sign in')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          key: const Key('userId'),
          controller: _userId,
          decoration: const InputDecoration(labelText: 'User id'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          decoration: const InputDecoration(labelText: 'Email (optional)'),
          keyboardType: TextInputType.emailAddress,
        ),
        if (widget.backend == null) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('userHash'),
            controller: _hash,
            decoration: const InputDecoration(
              labelText: 'User hash',
              helperText: 'hex(HMAC-SHA256(identitySecret, userId)), computed outside the app',
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('signIn'),
          onPressed: _busy ? null : _signIn,
          child: Text(_busy ? 'Signing in…' : 'Sign in'),
        ),
      ],
    ),
  );
}
