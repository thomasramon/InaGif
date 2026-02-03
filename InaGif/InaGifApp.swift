import SwiftUI
import AppKit

@main
struct InaGifApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // No visible window, just the settings if needed
        }
    }
}

