import SwiftUI

@main
struct QrScanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let appLanguage = AppLanguage.current()
    @State private var openScanner: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView(showScanner: $openScanner, appLanguage: appLanguage)
                .environment(\.locale, appLanguage.locale)
                .onAppear {
                    if ShortcutActionState.shared.consumePendingOpenScannerOnLaunch() {
                        openScanner = true
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .openScannerShortcut)) { _ in
                    openScanner = true
                }
        }
    }
}
