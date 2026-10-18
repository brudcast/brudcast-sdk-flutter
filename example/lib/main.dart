import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_in_app/brudcast_in_app.dart';
import 'package:brudcast_push/brudcast_push.dart';
import 'package:flutter/material.dart';

import 'action_log.dart';
import 'backend.dart';
import 'config.dart';
import 'push_setup.dart';
import 'router.dart';
import 'screens/account.dart';
import 'screens/home.dart';
import 'screens/inbox.dart';
import 'screens/shop.dart';
import 'screens/sign_in.dart';
import 'session.dart';
import 'theme.dart';

/// Starts the SDK the way an app should: the action handler first, so a push tap that launched the
/// app reaches it, then `initialize` once, before `runApp`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await SampleSession.load();
  await Brudcast.setActionHandler(handleAction);
  if (SampleConfig.publishableKey.isEmpty) {
    debugPrint('Pass BRUDCAST_PUBLISHABLE_KEY with --dart-define-from-file to start the SDK');
  } else {
    await Brudcast.initialize(
      SampleConfig.publishableKey,
      BrudcastOptions(
        environment: SampleConfig.environment,
        logLevel: BrudcastLogLevel.debug,
        accentColor: SampleTheme.primary,
        modules: const [BrudcastInApp.module, BrudcastPush.module],
      ),
    );
    if (SampleConfig.firebaseEnabled) await setUpPush();
  }
  final backend = SampleConfig.sampleBackendUrl.isEmpty ? null : SampleBackend(SampleConfig.sampleBackendUrl);
  runApp(SampleApp(session: session, backend: backend));
}

/// Records every action in the log, and routes the example's own `brudcast-sample:` links to its
/// screens. Everything else gets the SDK's default.
BrudcastActionResult handleAction(BrudcastAction action) {
  ActionLog.instance.record(action);
  final isOwnLink = action.kind == BrudcastActionKind.deeplink && action.value.startsWith('$deepLinkScheme:');
  if (!isOwnLink) return BrudcastActionResult.useDefault;
  return openDeepLink(Uri.parse(action.value)) ? BrudcastActionResult.handled : BrudcastActionResult.useDefault;
}

/// The example app.
class SampleApp extends StatelessWidget {
  /// Creates the app.
  const SampleApp({super.key, required this.session, this.backend});

  /// The signed-in user.
  final SampleSession session;

  /// The app's backend, when one is configured.
  final SampleBackend? backend;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Brudcast sample',
    theme: SampleTheme.light,
    darkTheme: SampleTheme.dark,
    navigatorKey: navigatorKey,
    navigatorObservers: [ScreenTracker()],
    initialRoute: session.isSignedIn ? Routes.home : Routes.signIn,
    routes: {
      Routes.signIn: (_) => SignInScreen(session: session, backend: backend),
      Routes.home: (_) => HomeScreen(session: session, backend: backend),
      Routes.shop: (_) => const ShopScreen(),
      Routes.product: (_) => const ProductScreen(),
      Routes.checkout: (_) => const CheckoutScreen(),
      Routes.account: (_) => AccountScreen(session: session),
      Routes.inbox: (_) => const InboxScreen(),
      Routes.inboxMessage: (_) => const InboxMessageScreen(),
    },
  );
}
