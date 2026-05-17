import AppKit
import SwiftUI
import Combine
import FirebaseCore
import GoogleSignIn

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        AuthService.bootstrap()

        // Restore a previous Google sign-in session if one exists.
        GIDSignIn.sharedInstance.restorePreviousSignIn { _, _ in }

        // Create the SwiftUI view that provides the contents of the popover.
        let contentView = PopoverView()

        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover

        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cricket.ball", accessibilityDescription: "Cricket Score")
            button.title = ""
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        setupSubscriptions()

        // Forward URL scheme callbacks (e.g. Google OAuth redirect) into GIDSignIn.
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard
            let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
            let url = URL(string: urlString)
        else { return }
        _ = AuthService.shared.handle(url: url)
    }
    
    private func setupSubscriptions() {
        let viewModel = LiveMatchViewModel.shared
        
        Publishers.CombineLatest(viewModel.$matches, viewModel.$selectedMatchId)
            .receive(on: RunLoop.main)
            .sink { [weak self] matches, selectedId in
                guard let self = self, let button = self.statusItem.button else { return }
                
                if let id = selectedId, let match = matches.first(where: { $0.id == id }), !match.score.isEmpty {
                    // Update menu bar with selected match score
                    button.title = match.score
                } else {
                    // Clear text, show only icon
                    button.title = ""
                }
            }
            .store(in: &cancellables)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.contentViewController = hostingController
            window.center()
            window.setFrameAutosaveName("Settings")
            window.isReleasedWhenClosed = false
            self.settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
