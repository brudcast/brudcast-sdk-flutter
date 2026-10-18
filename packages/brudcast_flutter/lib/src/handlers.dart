import 'dart:async';

import 'log.dart';

/// How long the SDK waits for a host handler before it uses the default.
const Duration brudcastHandlerTimeout = Duration(seconds: 2);

/// Runs a host handler, answering [fallback] when it throws or does not answer within
/// [brudcastHandlerTimeout], so a faulty handler never stalls a message, a notification or a link.
///
/// [name] names the handler in the warning logged on a fallback.
Future<T> runBrudcastHandler<T>(String name, FutureOr<T> Function() handler, T fallback) async {
  try {
    return await Future<T>.sync(handler).timeout(brudcastHandlerTimeout);
  } on TimeoutException {
    BrudcastLog.warning('The $name did not answer within two seconds; the default is used');
    return fallback;
  } catch (error) {
    BrudcastLog.error('The $name threw: $error');
    return fallback;
  }
}

/// Runs a call to the native SDK, logging instead of throwing when it fails, so no SDK call throws
/// into the app.
///
/// [name] names the call in the log.
Future<T?> guardBrudcastCall<T>(String name, Future<T> Function() call) async {
  try {
    return await call();
  } catch (error) {
    BrudcastLog.error('$name failed: $error');
    return null;
  }
}
