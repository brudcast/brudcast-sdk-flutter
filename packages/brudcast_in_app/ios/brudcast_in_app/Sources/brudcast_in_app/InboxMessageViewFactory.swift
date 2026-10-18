import Flutter
import UIKit
import Brudcast
import BrudcastInApp

/// Creates the platform views behind Dart's `BrudcastInboxMessage`: an inbox entry drawn by the
/// native renderer, which reports the height its design needs back to Dart.
final class InboxMessageViewFactory: NSObject, FlutterPlatformViewFactory {
    static let viewType = "com.brudcast.flutter/inbox_message"

    private let flutterApi: InAppFlutterApi

    init(flutterApi: InAppFlutterApi) {
        self.flutterApi = flutterApi
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let messageId = (args as? [String: Any])?["messageId"] as? String
        let message = messageId.flatMap { BrudcastInAppPlugin.seen[$0] }
        let view = message.flatMap { message in
            Brudcast.inApp.inbox.render(message) { [flutterApi] height in
                flutterApi.inboxMessageHeightChanged(viewId: viewId, height: Double(height)) { _ in }
            }
        } ?? UIView()
        view.frame = frame
        return InboxMessagePlatformView(view: view)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

private final class InboxMessagePlatformView: NSObject, FlutterPlatformView {
    private let content: UIView

    init(view: UIView) {
        content = view
    }

    func view() -> UIView {
        content
    }
}
