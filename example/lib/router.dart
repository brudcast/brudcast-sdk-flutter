import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:flutter/material.dart';

/// The example's screens, by route name. The names are also the `Brudcast.screen` names.
abstract final class Routes {
  static const String signIn = 'SignIn';
  static const String home = 'Home';
  static const String shop = 'Shop';
  static const String product = 'Product';
  static const String checkout = 'Checkout';
  static const String account = 'Account';
  static const String inbox = 'Inbox';
  static const String inboxMessage = 'InboxMessage';
}

/// The example's own deep link scheme. A campaign button set to `brudcast-sample://checkout` opens
/// checkout.
const String deepLinkScheme = 'brudcast-sample';

/// The navigator, so links from the SDK can open screens from outside the widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Opens the screen a `brudcast-sample:` link names.
///
/// Returns whether the link names a screen.
bool openDeepLink(Uri link) {
  final route = switch (link.host) {
    'shop' => Routes.shop,
    'checkout' => Routes.checkout,
    _ => null,
  };
  final navigator = navigatorKey.currentState;
  if (route == null || navigator == null) return false;
  navigator.pushNamed(route);
  return true;
}

/// Records a `Brudcast.screen` as each route appears, the way an app tracks its screens.
final class ScreenTracker extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _track(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _track(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _track(newRoute);

  void _track(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name != '/') Brudcast.screen(name);
  }
}
