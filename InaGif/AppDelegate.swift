import SwiftUI
import AppKit
import LaunchAtLogin

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var preferencesPopover: NSPopover!
    var eventMonitor: EventMonitor?

    @AppStorage("isCompactLayout") var isCompactLayout = false
    @AppStorage("recentSearches") var recentSearchesString: String = "" // Manage recent searches in AppStorage
    var contentViewModel = ContentViewModel() // The shared state

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item (the icon in the menu bar)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Setup the main GIF popover
        setupPopover()

        // Setup the preferences popover
        setupPreferencesPopover()

        // Event monitor to close the popover when clicking outside
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover.isShown ?? false {
                self?.closePopover(sender: event)
            }
        }

        // Ensure recent searches are limited when launching the app
        enforceRecentSearchLimit()

        // Close popover when app becomes inactive
        NotificationCenter.default.addObserver(self, selector: #selector(appDidResignActive), name: NSApplication.didResignActiveNotification, object: nil)
    }

    // Limit the number of recent searches to 5
    func enforceRecentSearchLimit() {
        var searches = recentSearchesString.components(separatedBy: ",").filter { !$0.isEmpty }

        // Keep only the last 5 searches
        if searches.count > 5 {
            searches = Array(searches.suffix(5))
            recentSearchesString = searches.joined(separator: ",")
        }
    }

    @objc func appDidResignActive() {
        if popover.isShown {
            closePopover(sender: nil)
        }
    }

    @objc func handleClick(_ sender: AnyObject?) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            if popover.isShown {
                closePopover(sender: sender)
            } else {
                showPopover(sender: sender)
            }
        }
    }

    func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            let popoverWidth: CGFloat = isCompactLayout ? 600 : 300

            popover.contentSize = NSSize(width: popoverWidth, height: 600)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
        }
    }

    func closePopover(sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()

        // Reset the ContentView's state when the popover is closed
        contentViewModel.resetState()

        // Enforce recent search limit when the popover closes
        enforceRecentSearchLimit()
    }

    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 600)
        popover.behavior = .transient
        popover.delegate = self

        let contentView = ContentView(viewModel: contentViewModel, openPreferences: openPreferences, toggleGifOption: toggleGifOption)
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(rootView: contentView)
    }

    func toggleGifOption() {
        isCompactLayout.toggle()
    }

    func openPreferences() {
        if preferencesPopover.isShown {
            preferencesPopover.performClose(nil)
        } else {
            showPreferencesPopover()
        }
    }

    func showPreferencesPopover() {
        if let button = statusItem.button {
            preferencesPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // This function is required to switch back to the main GIF popover
    func switchToMainPopover() {
        if preferencesPopover.isShown {
            preferencesPopover.performClose(nil)
        }
        showPopover(sender: nil) // Open the main popover
    }

    func setupPreferencesPopover() {
        preferencesPopover = NSPopover()
        preferencesPopover.contentSize = NSSize(width: 300, height: 150)
        preferencesPopover.behavior = .transient
        preferencesPopover.delegate = self

        let preferencesView = PreferencesView(switchToMainPopover: switchToMainPopover)
        preferencesPopover.contentViewController = NSViewController()
        preferencesPopover.contentViewController?.view = NSHostingView(rootView: preferencesView)
    }

    func showMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(openPreferencesFromMenu), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func openPreferencesFromMenu() {
        openPreferences()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
