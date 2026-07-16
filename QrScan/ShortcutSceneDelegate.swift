import UIKit
import Foundation

enum ShortcutAction {
    static let scanType = "com.github.QrScan.scan"
}

final class ShortcutActionState {
    static let shared = ShortcutActionState()
    private var pendingOpenScannerOnLaunch = false

    private init() {}

    @discardableResult
    func markPendingOpenScannerIfNeeded(shortcutItem: UIApplicationShortcutItem?) -> Bool {
        guard let shortcutItem, shortcutItem.type == ShortcutAction.scanType else {
            return false
        }
        pendingOpenScannerOnLaunch = true
        return true
    }

    @discardableResult
    func handleRuntimeShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard shortcutItem.type == ShortcutAction.scanType else {
            return false
        }
        NotificationCenter.default.post(name: .openScannerShortcut, object: nil)
        return true
    }

    func consumePendingOpenScannerOnLaunch() -> Bool {
        let shouldOpen = pendingOpenScannerOnLaunch
        pendingOpenScannerOnLaunch = false
        return shouldOpen
    }
}

class ShortcutSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        ShortcutActionState.shared.markPendingOpenScannerIfNeeded(
            shortcutItem: connectionOptions.shortcutItem
        )
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(ShortcutActionState.shared.handleRuntimeShortcut(shortcutItem))
    }
}

extension Notification.Name {
    static let openScannerShortcut = Notification.Name("openScannerShortcut")
}
