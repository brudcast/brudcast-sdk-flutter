import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:brudcast_flutter/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeHost implements BrudcastHostApi {
  final List<String> calls = [];
  PlatformOptions? options;
  String? publishableKey;
  Map<String, Object?>? properties;
  PlatformTraits? traits;
  bool fail = false;

  void _record(String call) {
    calls.add(call);
    if (fail) throw PlatformException(code: 'channel-error', message: 'Unable to establish connection');
  }

  @override
  Future<void> initialize(String publishableKey, PlatformOptions options) async {
    _record('initialize');
    this.publishableKey = publishableKey;
    this.options = options;
  }

  @override
  Future<void> identify(String externalId, String? userHash, PlatformTraits? traits) async {
    _record('identify $externalId $userHash');
    this.traits = traits;
  }

  @override
  Future<void> track(String name, Map<String, Object?> properties) async {
    _record('track $name');
    this.properties = properties;
  }

  @override
  Future<void> screen(String name, Map<String, Object?> properties) async {
    _record('screen $name');
    this.properties = properties;
  }

  @override
  Future<void> setActionHandlerEnabled(bool enabled) async => _record('actionHandler $enabled');

  @override
  Future<String?> deviceId() async {
    _record('deviceId');
    return 'device-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<PlatformActionResult> sendAction(PlatformAction action) async {
  const channel = 'dev.flutter.pigeon.brudcast_flutter.BrudcastFlutterApi.handleAction';
  final reply = await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    channel,
    BrudcastFlutterApi.pigeonChannelCodec.encodeMessage([action]),
    (_) {},
  );
  final decoded = BrudcastFlutterApi.pigeonChannelCodec.decodeMessage(reply) as List<Object?>;
  return decoded.single! as PlatformActionResult;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeHost host;

  setUp(() {
    host = FakeHost();
    Brudcast.hostApi = host;
  });

  tearDown(() => Brudcast.setActionHandler(null));

  test('initialize sends the options and the wrapper version', () async {
    await Brudcast.initialize(
      'bpk_123',
      const BrudcastOptions(
        environment: BrudcastEnvironment.local(port: 9000),
        logLevel: BrudcastLogLevel.debug,
        appearance: BrudcastAppearance.dark,
        accentColor: Color(0xFF3355FF),
        modules: [BrudcastModule('in_app'), BrudcastModule('push')],
        appGroupIdentifier: 'group.com.example',
      ),
    );

    final options = host.options!;
    expect(host.publishableKey, 'bpk_123');
    expect(options.environment.kind, PlatformEnvironmentKind.local);
    expect(options.environment.port, 9000);
    expect(options.environment.androidHost, '10.0.2.2');
    expect(options.logLevel, PlatformLogLevel.debug);
    expect(options.appearance, PlatformAppearance.dark);
    expect(options.accentColor, 0xFF3355FF);
    expect(options.modules, ['in_app', 'push']);
    expect(options.appGroupIdentifier, 'group.com.example');
    expect(options.wrapperVersion, brudcastFlutterVersion);
  });

  test('a custom environment carries its base URL', () async {
    await Brudcast.initialize(
      'bpk_123',
      BrudcastOptions(environment: BrudcastEnvironment.custom(Uri.parse('https://sdk.example.com/sdk/v1'))),
    );

    expect(host.options!.environment.kind, PlatformEnvironmentKind.custom);
    expect(host.options!.environment.baseUrl, 'https://sdk.example.com/sdk/v1');
  });

  test('track keeps strings, finite numbers, booleans and nulls', () async {
    await Brudcast.track('checkout_started', {
      'product': 'sneakers',
      'total': 120,
      'discount': 0.5,
      'gift': false,
      'note': null,
      'items': ['a'],
      'nested': {'a': 1},
      'when': DateTime(2026),
      'ratio': double.nan,
      'limit': double.infinity,
    });

    expect(host.properties, {'product': 'sneakers', 'total': 120, 'discount': 0.5, 'gift': false, 'note': null});
  });

  test('track refuses an invalid event name without calling native', () async {
    await Brudcast.track('1st event');
    await Brudcast.track('has space');
    await Brudcast.track('a' * 65);

    expect(host.calls, isEmpty);
  });

  test('screen filters properties too', () async {
    await Brudcast.screen('Checkout', {'step': 2, 'items': <int>[]});

    expect(host.calls, ['screen Checkout']);
    expect(host.properties, {'step': 2});
  });

  test('identify sends the hash and traits', () async {
    await Brudcast.identify(
      '4812',
      userHash: 'ab' * 32,
      traits: const BrudcastTraits(email: 'ada@example.com', firstName: 'Ada'),
    );

    expect(host.calls, ['identify 4812 ${'ab' * 32}']);
    expect(host.traits!.email, 'ada@example.com');
    expect(host.traits!.firstName, 'Ada');
    expect(host.traits!.phone, isNull);
  });

  test('a failing channel does not throw into the app', () async {
    host.fail = true;

    await expectLater(Brudcast.initialize('bpk_123'), completes);
    await expectLater(Brudcast.track('checkout_started'), completes);
    expect(await Brudcast.deviceId, isNull);
  });

  test('deviceId reads the native id', () async {
    expect(await Brudcast.deviceId, 'device-1');
  });

  test('isValidEventName applies the service rule', () {
    expect(Brudcast.isValidEventName('order.completed:v2-final_x'), isTrue);
    expect(Brudcast.isValidEventName('a${'b' * 63}'), isTrue);
    expect(Brudcast.isValidEventName('a${'b' * 64}'), isFalse);
    expect(Brudcast.isValidEventName('_private'), isFalse);
    expect(Brudcast.isValidEventName(''), isFalse);
  });

  group('the action handler', () {
    final action = PlatformAction(
      kind: PlatformActionKind.deeplink,
      value: 'myapp://checkout',
      opensInApp: false,
      source: PlatformActionSource.push,
      messageId: 'm1',
      verified: false,
    );

    test('setting it enables the native handler, and clearing it disables it', () async {
      await Brudcast.setActionHandler((_) => BrudcastActionResult.handled);
      await Brudcast.setActionHandler(null);

      expect(host.calls, ['actionHandler true', 'actionHandler false']);
    });

    test('receives the action and answers for it', () async {
      BrudcastAction? received;
      await Brudcast.setActionHandler((action) async {
        received = action;
        return BrudcastActionResult.handled;
      });

      expect(await sendAction(action), PlatformActionResult.handled);
      expect(received!.kind, BrudcastActionKind.deeplink);
      expect(received!.value, 'myapp://checkout');
      expect(received!.source, const BrudcastActionSource(origin: BrudcastActionOrigin.push, messageId: 'm1'));
      expect(received!.verified, isFalse);
    });

    test('a handler that throws gets the default', () async {
      await Brudcast.setActionHandler((_) => throw StateError('router not ready'));

      expect(await sendAction(action), PlatformActionResult.useDefault);
    });
  });
}
