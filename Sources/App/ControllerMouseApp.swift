import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var menuBarController: MenuBarController!
    private var gameControllerManager: GameControllerManager!
    private var appState: AppState!
    private var accessibilityHandler: AccessibilityPermissionHandler!

    private var clickDragHandler: ClickDragHandler!
    private var mouseController: MouseController!
    private var keyboardSimulator: KeyboardSimulator!
    private var inputHandler: ControllerInputHandler!

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState = AppState()
        accessibilityHandler = AccessibilityPermissionHandler()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gamecontroller.fill", accessibilityDescription: "ControllerMouse")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 480)
        popover.behavior = .transient
        popover.animates = true

        clickDragHandler = ClickDragHandler()
        mouseController = MouseController(appState: appState)
        keyboardSimulator = KeyboardSimulator()

        inputHandler = ControllerInputHandler(
            mouseController: mouseController,
            clickDragHandler: clickDragHandler,
            keyboardSimulator: keyboardSimulator,
            appState: appState
        )

        menuBarController = MenuBarController(
            statusItem: statusItem,
            popover: popover,
            appState: appState,
            inputHandler: inputHandler,
            accessibilityHandler: accessibilityHandler
        )

        gameControllerManager = GameControllerManager(
            inputHandler: inputHandler,
            appState: appState
        )

        gameControllerManager.onInput = { [weak inputHandler] gamepad in
            Task { @MainActor in
                inputHandler?.processExtendedGamepad(gamepad)
            }
        }

        gameControllerManager.startDiscovery()

        Task {
            await checkAccessibilityPermissions()
        }
    }

    @objc func togglePopover() {
        Task { @MainActor in
            menuBarController.togglePopover()
        }
    }

    @MainActor
    private func checkAccessibilityPermissions() async {
        if !accessibilityHandler.checkAccessibilityPermission() {
            accessibilityHandler.requestAccessibilityPermission()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        gameControllerManager.stopDiscovery()
        mouseController.stop()
    }
}