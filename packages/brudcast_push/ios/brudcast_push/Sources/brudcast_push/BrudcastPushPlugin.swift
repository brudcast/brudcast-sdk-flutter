import Flutter
import UIKit
import Combine
import UserNotifications
import Brudcast
import BrudcastPush

/// The Brudcast push plugin: registers the native push module, forwards Dart calls to it, routes the
/// notification handler to Dart, and passes notification taps and foreground notifications to the
/// SDK from Flutter's app and scene delegates, so opens are recorded with no Dart code.
public final class BrudcastPushPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate, PushHostApi {
    /// The engine whose Dart set the notification handler, so a background engine cannot take it.
    private static weak var handlerOwner: BrudcastPushPlugin?

    /// The responses already passed to the SDK. A launch tap can arrive both in the scene's
    /// connection options and through the notification center delegate. Touched on the main queue.
    private static var handledResponses: Set<String> = []

    private static let moduleObserver: NSObjectProtocol = NotificationCenter.default.addObserver(
        forName: Notification.Name("com.brudcast.flutter.modules"),
        object: nil,
        queue: nil
    ) { notification in
        (notification.userInfo?["register"] as? (BrudcastModule) -> Void)?(BrudcastPush.module)
    }

    private let messenger: FlutterBinaryMessenger
    private let flutterApi: PushFlutterApi

    private init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        flutterApi = PushFlutterApi(binaryMessenger: messenger)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        _ = moduleObserver
        let plugin = BrudcastPushPlugin(messenger: registrar.messenger())
        PushHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: plugin)
        PermissionChangesStreamHandler.register(with: registrar.messenger(), streamHandler: PermissionStream())
        registrar.addApplicationDelegate(plugin)
        registrar.addSceneDelegate(plugin)
        registrar.publish(plugin)
        adoptNotificationCenter()
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        clearNotificationHandler()
        PushHostApiSetup.setUp(binaryMessenger: messenger, api: nil)
    }

    /// Makes Flutter's app delegate the notification center's delegate when nothing else is, so it
    /// forwards notification callbacks to every plugin, this one included.
    private static func adoptNotificationCenter() {
        let center = UNUserNotificationCenter.current()
        guard center.delegate == nil, let appDelegate = UIApplication.shared.delegate as? FlutterAppLifeCycleProvider else { return }
        center.delegate = appDelegate
    }

    /// Whether `firebase_messaging` is installed. It calls the notification center's completion
    /// handlers itself, and a second call is ignored or logged by the system, so this plugin leaves
    /// them to it.
    private static var firebaseAnswers: Bool {
        NSClassFromString("FLTFirebaseMessagingPlugin") != nil
    }

    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
        if let response = connectionOptions?.notificationResponse {
            Self.handle(response)
        }
        return false
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let isBrudcast = Self.handle(response)
        if isBrudcast, !Self.firebaseAnswers {
            completionHandler()
        }
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if Self.firebaseAnswers {
            _ = Brudcast.push.presentationOptions(for: notification)
        } else {
            Brudcast.push.presentationOptions(for: notification, completionHandler: completionHandler)
        }
    }

    /// Passes a notification response to the SDK once.
    ///
    /// - Parameter response: The response.
    /// - Returns: True when the notification is from Brudcast.
    @discardableResult
    private static func handle(_ response: UNNotificationResponse) -> Bool {
        let key = "\(response.notification.request.identifier)|\(response.actionIdentifier)"
        guard Brudcast.push.isBrudcastNotification(response.notification.request.content.userInfo) else { return false }
        guard handledResponses.insert(key).inserted else { return true }
        Brudcast.push.handleNotificationResponse(response)
        return true
    }

    func setToken(token: String) throws {
        Brudcast.push.setToken(token)
    }

    func requestPermission(provisional: Bool, completion: @escaping (Result<PlatformPushPermission, Error>) -> Void) {
        Brudcast.push.requestPermission(provisional: provisional) { status in
            completion(.success(status.platform))
        }
    }

    func setNotificationHandlerEnabled(enabled: Bool) throws {
        guard enabled else { return clearNotificationHandler() }
        Self.handlerOwner = self
        Brudcast.push.setAsyncNotificationHandler { notification, decide in
            guard let owner = Self.handlerOwner else { return decide(.show) }
            owner.flutterApi.handleNotification(notification: notification.platform) { result in
                if case .success(.suppress) = result {
                    decide(.suppress)
                } else {
                    decide(.show)
                }
            }
        }
    }

    func handleForegroundMessage(data: [String: String], title: String?, body: String?, imageUrl: String?) throws -> Bool {
        Brudcast.push.isBrudcastNotification(data)
    }

    private func clearNotificationHandler() {
        guard Self.handlerOwner === self else { return }
        Self.handlerOwner = nil
        Brudcast.push.setAsyncNotificationHandler(nil)
    }
}

/// Streams the permission status to Dart, starting with the current status.
private final class PermissionStream: PermissionChangesStreamHandler {
    private var subscription: AnyCancellable?

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<PlatformPushPermission>) {
        subscription = Brudcast.push.permissionPublisher
            .prepend(Brudcast.push.permissionStatus)
            .removeDuplicates()
            .sink { sink.success($0.platform) }
    }

    override func onCancel(withArguments arguments: Any?) {
        subscription = nil
    }
}

private extension BrudcastPushPermission {
    var platform: PlatformPushPermission {
        switch self {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .provisional: return .provisional
        }
    }
}

private extension BrudcastPushNotification {
    var platform: PlatformPushNotification {
        PlatformPushNotification(
            messageId: messageId,
            campaignId: campaignId,
            applicationId: applicationId,
            title: title,
            body: body,
            clickUrl: clickURL?.absoluteString,
            data: data
        )
    }
}
