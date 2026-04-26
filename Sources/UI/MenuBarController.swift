import AppKit
import SwiftUI
import Combine

@MainActor
final class MenuBarController: NSObject, ObservableObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let appState: AppState
    private let inputHandler: ControllerInputHandler
    private let accessibilityHandler: AccessibilityPermissionHandler
    private var cancellables = Set<AnyCancellable>()

    init(
        statusItem: NSStatusItem,
        popover: NSPopover,
        appState: AppState,
        inputHandler: ControllerInputHandler,
        accessibilityHandler: AccessibilityPermissionHandler
    ) {
        self.statusItem = statusItem
        self.popover = popover
        self.appState = appState
        self.inputHandler = inputHandler
        self.accessibilityHandler = accessibilityHandler
        super.init()
        setupPopover()
        updateStatusItemAppearance()
        observeAppState()
    }

    private func observeAppState() {
        appState.$isControllerConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
            }
            .store(in: &cancellables)

        appState.$isActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
            }
            .store(in: &cancellables)
    }

    private func setupPopover() {
        let settingsView = SettingsView(
            appState: appState,
            inputHandler: inputHandler,
            accessibilityHandler: accessibilityHandler
        )
        popover.contentViewController = NSHostingController(rootView: settingsView)
    }

    func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func closePopover() {
        popover.performClose(nil)
    }

    private func updateStatusItemAppearance() {
        if appState.isControllerConnected && appState.isActive {
            statusItem.button?.image = NSImage(
                systemSymbolName: "gamecontroller.fill",
                accessibilityDescription: "ControllerMouse Active"
            )?.withSymbolConfiguration(.init(hierarchicalColor: .systemGreen))
        } else if appState.isControllerConnected {
            statusItem.button?.image = NSImage(
                systemSymbolName: "gamecontroller",
                accessibilityDescription: "ControllerMouse"
            )
        } else {
            statusItem.button?.image = NSImage(
                systemSymbolName: "gamecontroller",
                accessibilityDescription: "ControllerMouse"
            )?.withSymbolConfiguration(.init(hierarchicalColor: .secondaryLabelColor))
        }
    }
}