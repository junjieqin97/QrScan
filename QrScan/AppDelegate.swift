import UIKit
import Foundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let language = AppLanguage.current()
        let scanShortcut = UIApplicationShortcutItem(
            type: ShortcutAction.scanType,
            localizedTitle: L10n.tr("shortcut.scan.title", language: language),
            localizedSubtitle: L10n.tr("shortcut.scan.subtitle", language: language),
            icon: UIApplicationShortcutIcon(systemImageName: "qrcode.viewfinder"),
            userInfo: nil
        )
        application.shortcutItems = [scanShortcut]
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = ShortcutSceneDelegate.self
        return configuration
    }
}
