import SwiftUI

@main
struct RetroBirthApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Bonus: Disables the "Maximize/Zoom" green button so the window stays thin
        if let window = NSApp.windows.first {
            window.collectionBehavior = .fullScreenAuxiliary
            window.standardWindowButton(.zoomButton)?.isEnabled = false
        }
    }
}
