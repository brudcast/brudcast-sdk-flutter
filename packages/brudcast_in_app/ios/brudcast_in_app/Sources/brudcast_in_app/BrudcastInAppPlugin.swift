import Flutter
import UIKit
import Combine
import Brudcast
import BrudcastInApp

/// The Brudcast in-app plugin: registers the native in-app module, forwards Dart calls to it, routes
/// the message handler to Dart, and draws inbox entries as platform views.
public final class BrudcastInAppPlugin: NSObject, FlutterPlugin, InAppHostApi {
    /// The engine whose Dart set the message handler, so a background engine cannot take it.
    private static weak var handlerOwner: BrudcastInAppPlugin?

    /// Messages that crossed to Dart, so a platform view can draw one by id. Touched on the main queue.
    static var seen: [String: BrudcastInAppMessage] = [:]

    private static let moduleObserver: NSObjectProtocol = NotificationCenter.default.addObserver(
        forName: Notification.Name("com.brudcast.flutter.modules"),
        object: nil,
        queue: nil
    ) { notification in
        (notification.userInfo?["register"] as? (BrudcastModule) -> Void)?(BrudcastInApp.module)
    }

    private let messenger: FlutterBinaryMessenger
    private let flutterApi: InAppFlutterApi

    private init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        flutterApi = InAppFlutterApi(binaryMessenger: messenger)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        _ = moduleObserver
        let plugin = BrudcastInAppPlugin(messenger: registrar.messenger())
        InAppHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: plugin)
        UnreadCountChangesStreamHandler.register(with: registrar.messenger(), streamHandler: UnreadCountStream())
        registrar.register(InboxMessageViewFactory(flutterApi: plugin.flutterApi), withId: InboxMessageViewFactory.viewType)
        registrar.publish(plugin)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        clearMessageHandler()
        InAppHostApiSetup.setUp(binaryMessenger: messenger, api: nil)
    }

    func pauseDisplay() throws {
        Brudcast.inApp.pauseDisplay()
    }

    func resumeDisplay() throws {
        Brudcast.inApp.resumeDisplay()
    }

    func sync() throws {
        Brudcast.inApp.sync()
    }

    func setMessageHandlerEnabled(enabled: Bool) throws {
        guard enabled else { return clearMessageHandler() }
        Self.handlerOwner = self
        Brudcast.inApp.setAsyncMessageHandler { message, decide in
            Self.seen[message.id] = message
            guard let owner = Self.handlerOwner else { return decide(.show) }
            owner.flutterApi.handleMessage(message: message.platform) { result in
                switch result {
                case .success(.suppress): decide(.suppress)
                case .success(.deferred): decide(.defer)
                case .success(.custom): decide(.custom)
                default: decide(.show)
                }
            }
        }
    }

    func reportImpression(messageId: String) throws {
        Brudcast.inApp.reportImpression(messageId: messageId)
    }

    func reportClick(messageId: String, buttonId: String) throws {
        Brudcast.inApp.reportClick(messageId: messageId, buttonId: buttonId)
    }

    func reportDismiss(messageId: String) throws {
        Brudcast.inApp.reportDismiss(messageId: messageId)
    }

    func presentInbox(title: String) throws {
        Brudcast.inApp.inbox.present(title: title)
    }

    func listInbox(beforeMillis: Int64?, limit: Int64, completion: @escaping (Result<PlatformInboxPage, Error>) -> Void) {
        let before = beforeMillis.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
        Brudcast.inApp.inbox.list(before: before, limit: Int(limit)) { result in
            switch result {
            case .success(let page):
                page.messages.forEach { Self.seen[$0.id] = $0 }
                completion(.success(PlatformInboxPage(messages: page.messages.map(\.platform), unreadCount: Int64(page.unreadCount), hasMore: page.hasMore)))
            case .failure(let error):
                completion(.failure(PigeonError(code: error.code ?? "inbox_failed", message: error.message, details: nil)))
            }
        }
    }

    func markRead(messageId: String) throws {
        Brudcast.inApp.inbox.markRead(messageId)
    }

    func delete(messageId: String) throws {
        Brudcast.inApp.inbox.delete(messageId)
    }

    private func clearMessageHandler() {
        guard Self.handlerOwner === self else { return }
        Self.handlerOwner = nil
        Brudcast.inApp.setAsyncMessageHandler(nil)
    }
}

/// Streams the inbox's unread count to Dart, starting with the current count.
private final class UnreadCountStream: UnreadCountChangesStreamHandler {
    private var subscription: AnyCancellable?

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<Int64>) {
        subscription = Brudcast.inApp.inbox.unreadCountPublisher
            .prepend(Brudcast.inApp.inbox.unreadCount)
            .removeDuplicates()
            .sink { sink.success(Int64($0)) }
    }

    override func onCancel(withArguments arguments: Any?) {
        subscription = nil
    }
}

extension BrudcastInAppMessage {
    var platform: PlatformInAppMessage {
        let format: PlatformMessageFormat
        switch self.format {
        case .modal: format = .modal
        case .banner: format = .banner
        case .fullscreen: format = .fullscreen
        case .inboxOnly: format = .inboxOnly
        }
        let designJSON = (try? JSONSerialization.data(withJSONObject: design)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return PlatformInAppMessage(
            id: id,
            campaignId: campaignId,
            format: format,
            isTest: isTest,
            title: title,
            preview: preview,
            thumbnailUrl: thumbnailURL?.absoluteString,
            isRead: isRead,
            createdAtMillis: Int64((createdAt.timeIntervalSince1970 * 1000).rounded()),
            design: designJSON
        )
    }
}
