import Flutter
import UIKit
import Brudcast

/// The core Brudcast plugin: forwards Dart calls to the native SDK and Dart's action handler to it.
public final class BrudcastFlutterPlugin: NSObject, FlutterPlugin, BrudcastHostApi, ActionRouterTarget {
    private static let router = ActionRouter(
        clock: { ProcessInfo.processInfo.systemUptime },
        schedule: { delay, block in DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block) },
        install: { Brudcast.setAsyncActionHandler($0) },
        performDefault: { Brudcast.performDefaultAction($0) }
    )

    private let flutterApi: BrudcastFlutterApi
    private let messenger: FlutterBinaryMessenger

    private init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        flutterApi = BrudcastFlutterApi(binaryMessenger: messenger)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = BrudcastFlutterPlugin(messenger: registrar.messenger())
        BrudcastHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: plugin)
        registrar.publish(plugin)
        router.engineAttached()
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        Self.router.clearTarget(self)
        BrudcastHostApiSetup.setUp(binaryMessenger: messenger, api: nil)
    }

    func initialize(publishableKey: String, options: PlatformOptions) throws {
        BrudcastSDK.setWrapper(name: "Flutter", version: options.wrapperVersion)
        Brudcast.initialize(publishableKey: publishableKey, options: options.native)
    }

    func identify(externalId: String, userHash: String?, traits: PlatformTraits?) throws {
        Brudcast.identify(externalId: externalId, userHash: userHash, traits: traits?.native)
    }

    func reset() throws {
        Brudcast.reset()
    }

    func track(name: String, properties: [String: Any?]) throws {
        Brudcast.track(name, properties: Self.properties(properties))
    }

    func screen(name: String, properties: [String: Any?]) throws {
        Brudcast.screen(name, properties: Self.properties(properties))
    }

    func setOptedOut(optedOut: Bool) throws {
        optedOut ? Brudcast.optOut() : Brudcast.optIn()
    }

    func setTrackingEnabled(enabled: Bool) throws {
        enabled ? Brudcast.enableTracking() : Brudcast.disableTracking()
    }

    func flush() throws {
        Brudcast.flush()
    }

    func setActionHandlerEnabled(enabled: Bool) throws {
        enabled ? Self.router.setTarget(self) : Self.router.clearTarget(self)
    }

    func deviceId() throws -> String? {
        Brudcast.deviceId
    }

    func handle(_ action: BrudcastAction, decide: @escaping (BrudcastActionResult) -> Void) {
        flutterApi.handleAction(action: action.platform) { result in
            if case .success(.handled) = result {
                decide(.handled)
            } else {
                decide(.useDefault)
            }
        }
    }

    /// Converts properties from the channel, which Dart has already limited to strings, numbers,
    /// booleans and nulls.
    ///
    /// - Parameter raw: The properties.
    /// - Returns: The properties the SDK takes.
    private static func properties(_ raw: [String: Any?]) -> BrudcastProperties {
        var properties: BrudcastProperties = [:]
        for (key, value) in raw {
            properties[key] = BrudcastValue.from(value)
        }
        return properties
    }
}

private extension PlatformOptions {
    var native: BrudcastOptions {
        BrudcastOptions(
            environment: environment.native,
            logLevel: logLevel.native,
            appearance: appearance.native,
            modules: BrudcastModuleRegistry.resolve(modules),
            appGroupIdentifier: appGroupIdentifier,
            accentColor: accentColor.map(UIColor.init(argb:))
        )
    }
}

private extension PlatformEnvironment {
    var native: BrudcastEnvironment {
        switch kind {
        case .production: return .production
        case .staging: return .staging
        case .uat: return .uat
        case .development: return .development
        case .local: return .local(port: port.map { Int($0) } ?? 8191)
        case .custom:
            guard let baseUrl = baseUrl, let url = URL(string: baseUrl) else {
                BrudcastLogger.shared.error("A custom environment needs a base URL; using production")
                return .production
            }
            return .custom(url)
        }
    }
}

private extension PlatformLogLevel {
    var native: BrudcastLogLevel {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .none: return .none
        }
    }
}

private extension PlatformAppearance {
    var native: BrudcastAppearance {
        switch self {
        case .system: return .system
        case .light: return .light
        case .dark: return .dark
        }
    }
}

private extension PlatformTraits {
    var native: BrudcastTraits {
        BrudcastTraits(email: email, phone: phone, firstName: firstName, lastName: lastName, language: language, timezone: timezone)
    }
}

private extension BrudcastAction {
    var platform: PlatformAction {
        let kind: PlatformActionKind
        switch self.kind {
        case .deeplink: kind = .deeplink
        case .url: kind = .url
        case .customEvent: kind = .customEvent
        }
        switch source {
        case .inApp(let messageId, let buttonId):
            return PlatformAction(kind: kind, value: value, opensInApp: opensInApp, source: .inApp, messageId: messageId, buttonId: buttonId, verified: verified)
        case .push(let messageId):
            return PlatformAction(kind: kind, value: value, opensInApp: opensInApp, source: .push, messageId: messageId, verified: verified)
        }
    }
}

private extension UIColor {
    convenience init(argb: Int64) {
        let value = UInt32(truncatingIfNeeded: argb)
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: CGFloat((value >> 24) & 0xFF) / 255
        )
    }
}
