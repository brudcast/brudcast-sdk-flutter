import 'dart:async';

import 'package:brudcast_example/backend.dart';
import 'package:brudcast_example/config.dart';
import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_in_app/brudcast_in_app.dart';
import 'package:brudcast_push/brudcast_push.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Runs the SDK against a real service and the sample backend, from the configuration the example
/// uses: `flutter test integration_test --dart-define-from-file=config/local.json`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a signed-in user receives a message the backend sends', (tester) async {
    expect(SampleConfig.publishableKey, isNotEmpty, reason: 'Pass BRUDCAST_PUBLISHABLE_KEY');
    expect(SampleConfig.sampleBackendUrl, isNotEmpty, reason: 'Pass SAMPLE_BACKEND_URL');

    final messages = StreamController<BrudcastInAppMessage>.broadcast();
    await Brudcast.inApp.setMessageHandler((message) {
      messages.add(message);
      return BrudcastMessageDecision.show;
    });
    await Brudcast.initialize(
      SampleConfig.publishableKey,
      BrudcastOptions(
        environment: SampleConfig.environment,
        logLevel: BrudcastLogLevel.debug,
        modules: const [BrudcastInApp.module, BrudcastPush.module],
      ),
    );
    expect(await Brudcast.deviceId, isNotNull);

    final backend = SampleBackend(SampleConfig.sampleBackendUrl);
    final user = await backend.login('flutter-e2e-${DateTime.now().millisecondsSinceEpoch}', null);
    await Brudcast.identify(user.externalId, userHash: user.userHash);
    await Brudcast.track('flutter_e2e_started', {'platform': 'flutter'});

    final arrived = messages.stream.first;
    await _sendWelcome(backend, user.externalId);
    final message = await arrived.timeout(const Duration(seconds: 45));
    expect(message.id, isNotEmpty);
    expect(message.title, isNotEmpty);

    final page = await Brudcast.inApp.inbox.list(limit: 10);
    expect(page.unreadCount, greaterThanOrEqualTo(0));

    await Brudcast.flush();
    await Brudcast.reset();
  });
}

/// Sends the welcome once Brudcast has created the contact, which follows the first identified
/// session by a moment.
Future<void> _sendWelcome(SampleBackend backend, String externalId) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (true) {
    try {
      return await backend.sendWelcome(externalId);
    } on SampleBackendException {
      if (DateTime.now().isAfter(deadline)) rethrow;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
}
