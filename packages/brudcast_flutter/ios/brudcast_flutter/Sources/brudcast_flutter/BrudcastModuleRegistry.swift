import Foundation
import Brudcast

/// The native modules the installed Brudcast plugins provide.
///
/// `brudcast_in_app` and `brudcast_push` do not depend on this plugin's Swift package, so they
/// cannot call it. They observe the `com.brudcast.flutter.modules` notification instead, and answer
/// it by calling the `(BrudcastModule) -> Void` closure under `register` in its user info.
enum BrudcastModuleRegistry {
    static let requestNotification = Notification.Name("com.brudcast.flutter.modules")
    static let registerKey = "register"

    /// Collects the installed modules and finds the ones Dart listed, logging each one whose plugin
    /// is not installed.
    ///
    /// - Parameter names: The module names, such as `in_app` and `push`.
    /// - Returns: The modules found, in the order given.
    static func resolve(_ names: [String]) -> [BrudcastModule] {
        var installed: [String: BrudcastModule] = [:]
        let register: (BrudcastModule) -> Void = { module in installed[module.name] = module }
        NotificationCenter.default.post(name: requestNotification, object: nil, userInfo: [registerKey: register])
        var seen: Set<String> = []
        return names.compactMap { name in
            guard seen.insert(name).inserted else { return nil }
            guard let module = installed[name] else {
                BrudcastLogger.shared.error("The \(name) module was listed, but its Flutter package is not installed; add \(packageName(for: name)) to pubspec.yaml")
                return nil
            }
            return module
        }
    }

    private static func packageName(for name: String) -> String {
        switch name {
        case "in_app": return "brudcast_in_app"
        case "push": return "brudcast_push"
        default: return "the package for \(name)"
        }
    }
}
