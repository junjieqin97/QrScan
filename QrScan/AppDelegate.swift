import UIKit
import Foundation

/// App delegate to handle legacy shortcut actions coming from the system
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == "com.example3636.QrScan.scan" {
            NotificationCenter.default.post(name: .openScannerShortcut, object: nil)
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }
}

extension Notification.Name {
    static let openScannerShortcut = Notification.Name("openScannerShortcut")
}
