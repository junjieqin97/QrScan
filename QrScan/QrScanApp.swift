import SwiftUI

@main
struct QrScanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var openScanner: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView(showScanner: $openScanner)
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
