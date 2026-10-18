import 'package:flutter/foundation.dart';

import 'action.dart';
import 'handlers.dart';
import 'log.dart';
import 'messages.g.dart';
import 'options.dart';
import 'properties.dart';
import 'version.dart';

/// The Brudcast SDK. Use it through the [Brudcast] constant.
///
/// Call [initialize] once, early in `main`. Every other call may come before it: the native SDK
/// holds calls made earlier and runs them once it starts. No call throws into the app; failures are
/// logged.
final class BrudcastSdk {
  BrudcastSdk._();

  static final RegExp _eventName = RegExp(r'^[A-Za-z][A-Za-z0-9_.:-]{0,63}$');

  BrudcastHostApi _host = BrudcastHostApi();
  BrudcastActionHandler? _actionHandler;

  /// Replaces the channel to the native SDK, for tests.
  @visibleForTesting
  set hostApi(BrudcastHostApi host) => _host = host;

  /// Starts the SDK.
  ///
  /// [publishableKey] is the application's publishable key (`bpk_...`) from the dashboard. It is
  /// public by design; never ship the identity secret in the app. [options] picks the environment,
  /// logging, appearance and the modules to run.
  Future<void> initialize(String publishableKey, [BrudcastOptions options = const BrudcastOptions()]) async {
    assert(publishableKey.trim().isNotEmpty, 'Brudcast.initialize needs a publishable key');
    BrudcastLog.level = options.logLevel;
    await guardBrudcastCall('initialize', () => _host.initialize(publishableKey, _platformOptions(options)));
  }

  /// Identifies the signed-in user.
  ///
  /// [externalId] is your id for the user, at most 191 characters. [userHash] is
  /// `HMAC-SHA256(identitySecret, externalId)` in hex, computed on your server; it is required when
  /// the application enforces identity verification. [traits] fill the contact Brudcast creates.
  Future<void> identify(String externalId, {String? userHash, BrudcastTraits? traits}) async {
    final platformTraits = traits == null
        ? null
        : PlatformTraits(
            email: traits.email,
            phone: traits.phone,
            firstName: traits.firstName,
            lastName: traits.lastName,
            language: traits.language,
            timezone: traits.timezone,
          );
    await guardBrudcastCall('identify', () => _host.identify(externalId, userHash, platformTraits));
  }

  /// Forgets the user on logout. The device keeps its id, and its push token stops reaching the
  /// previous user.
  Future<void> reset() async {
    await guardBrudcastCall('reset', _host.reset);
  }

  /// Records a custom event. In-app messages triggered by it show at once.
  ///
  /// [name] is a letter, then up to 63 letters, digits and `_ . : -`. [properties] hold strings,
  /// numbers, booleans and nulls; other values are dropped with a warning.
  Future<void> track(String name, [Map<String, Object?> properties = const {}]) async {
    if (!isValidEventName(name)) {
      BrudcastLog.error(
        'track ignored "$name": names start with a letter and use at most 64 letters, digits and _ . : -',
      );
      return;
    }
    await guardBrudcastCall('track', () => _host.track(name, brudcastProperties(properties)));
  }

  /// Records that the user is on a screen. In-app messages triggered by it show at once.
  ///
  /// [properties] hold strings, numbers, booleans and nulls; other values are dropped with a
  /// warning.
  Future<void> screen(String name, [Map<String, Object?> properties = const {}]) async {
    await guardBrudcastCall('screen', () => _host.screen(name, brudcastProperties(properties)));
  }

  /// Stops in-app campaign messages for this user. Transactional messages still arrive.
  Future<void> optOut() async {
    await guardBrudcastCall('optOut', () => _host.setOptedOut(true));
  }

  /// Resumes in-app campaign messages for this user.
  Future<void> optIn() async {
    await guardBrudcastCall('optIn', () => _host.setOptedOut(false));
  }

  /// Stops collecting and sending events, for consent frameworks. Waiting events are discarded.
  Future<void> disableTracking() async {
    await guardBrudcastCall('disableTracking', () => _host.setTrackingEnabled(false));
  }

  /// Resumes collecting events after [disableTracking].
  Future<void> enableTracking() async {
    await guardBrudcastCall('enableTracking', () => _host.setTrackingEnabled(true));
  }

  /// Sends waiting events now instead of on the next timer tick.
  Future<void> flush() async {
    await guardBrudcastCall('flush', _host.flush);
  }

  /// Sets the handler for deep links, URLs and custom events from in-app buttons and push taps.
  /// Return [BrudcastActionResult.handled] to skip the default behaviour, which opens the link.
  ///
  /// Set it early, before `runApp`: a push tap that launched the app waits up to five seconds for
  /// it. Pass null to restore the defaults.
  Future<void> setActionHandler(BrudcastActionHandler? handler) async {
    _actionHandler = handler;
    BrudcastFlutterApi.setUp(handler == null ? null : _ActionReceiver(this));
    await guardBrudcastCall('setActionHandler', () => _host.setActionHandlerEnabled(handler != null));
  }

  /// This install's device id, a random UUID the native SDK keeps. Null before [initialize].
  Future<String?> get deviceId => guardBrudcastCall<String?>('deviceId', _host.deviceId);

  /// Checks an event name against the rule the service applies: a letter followed by up to 63
  /// letters, digits and `_ . : -`.
  bool isValidEventName(String name) => _eventName.hasMatch(name);

  Future<BrudcastActionResult> _handleAction(BrudcastAction action) {
    final handler = _actionHandler;
    if (handler == null) return Future.value(BrudcastActionResult.useDefault);
    return runBrudcastHandler('action handler', () => handler(action), BrudcastActionResult.useDefault);
  }

  static PlatformOptions _platformOptions(BrudcastOptions options) => PlatformOptions(
    environment: PlatformEnvironment(
      kind: PlatformEnvironmentKind.values.byName(options.environment.name),
      androidHost: options.environment.androidHost,
      port: options.environment.port,
      baseUrl: options.environment.baseUrl,
    ),
    logLevel: PlatformLogLevel.values.byName(options.logLevel.name),
    appearance: PlatformAppearance.values.byName(options.appearance.name),
    accentColor: options.accentColor?.toARGB32(),
    modules: options.modules.map((module) => module.name).toList(),
    appGroupIdentifier: options.appGroupIdentifier,
    wrapperVersion: brudcastFlutterVersion,
  );
}

/// The Brudcast SDK.
// ignore: non_constant_identifier_names
final BrudcastSdk Brudcast = BrudcastSdk._();

final class _ActionReceiver implements BrudcastFlutterApi {
  _ActionReceiver(this._sdk);

  final BrudcastSdk _sdk;

  @override
  Future<PlatformActionResult> handleAction(PlatformAction action) async {
    final result = await _sdk._handleAction(_action(action));
    return switch (result) {
      BrudcastActionResult.handled => PlatformActionResult.handled,
      BrudcastActionResult.useDefault => PlatformActionResult.useDefault,
    };
  }

  static BrudcastAction _action(PlatformAction action) => BrudcastAction(
    kind: switch (action.kind) {
      PlatformActionKind.deeplink => BrudcastActionKind.deeplink,
      PlatformActionKind.url => BrudcastActionKind.url,
      PlatformActionKind.customEvent => BrudcastActionKind.customEvent,
    },
    value: action.value,
    opensInApp: action.opensInApp,
    source: BrudcastActionSource(
      origin: switch (action.source) {
        PlatformActionSource.inApp => BrudcastActionOrigin.inApp,
        PlatformActionSource.push => BrudcastActionOrigin.push,
      },
      messageId: action.messageId,
      buttonId: action.buttonId,
    ),
    verified: action.verified,
  );
}
