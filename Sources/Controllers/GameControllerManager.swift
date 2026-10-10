import Foundation
import GameController
import Combine

@MainActor
final class GameControllerManager: ObservableObject {
    @Published var connectedController: GCController?
    @Published var isSearching: Bool = false

    var onInput: ((GCExtendedGamepad) -> Void)?

    private let inputHandler: ControllerInputHandler
    private let appState: AppState
    private var displayLink: CVDisplayLink?
    private var isRunning = false

    init(inputHandler: ControllerInputHandler, appState: AppState) {
        self.inputHandler = inputHandler
        self.appState = appState
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            Task { @MainActor [weak self] in
                self?.handleControllerConnected(controller)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            Task { @MainActor [weak self] in
                self?.handleControllerDisconnected(controller)
            }
        }
    }

    func startDiscovery() {
        GCController.startWirelessControllerDiscovery { [weak self] in
            Task { @MainActor [weak self] in
                self?.isSearching = false
            }
        }
        isSearching = true

        if let controller = GCController.controllers().first {
            handleControllerConnected(controller)
        }
    }

    func stopDiscovery() {
        GCController.stopWirelessControllerDiscovery()
        stopInputPolling()
    }

    private func handleControllerConnected(_ controller: GCController) {
        connectedController = controller
        appState.isControllerConnected = true
        appState.controllerName = controller.vendorName

        if controller.extendedGamepad != nil {
            startInputPolling()
        }
    }

    private func handleControllerDisconnected(_ controller: GCController) {
        if connectedController == controller {
            connectedController = nil
            appState.isControllerConnected = false
            appState.controllerName = nil
            stopInputPolling()
        }
    }

    private func startInputPolling() {
        guard !isRunning else { return }
        isRunning = true

        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let displayLink = displayLink else { return }

        let opaquePointer = Unmanaged.passUnretained(self).toOpaque()

        CVDisplayLinkSetOutputCallback(
            displayLink,
            { (displayLink: CVDisplayLink,
               inNow: UnsafePointer<CVTimeStamp>,
               inOutputTime: UnsafePointer<CVTimeStamp>,
               flagsIn: CVOptionFlags,
               flagsOut: UnsafeMutablePointer<CVOptionFlags>,
               displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in
                guard let context = displayLinkContext else { return kCVReturnError }
                let manager = Unmanaged<GameControllerManager>.fromOpaque(context).takeUnretainedValue()
                Task { @MainActor in
                    manager.pollControllerInput()
                }
                return kCVReturnSuccess
            },
            opaquePointer
        )

        CVDisplayLinkStart(displayLink)
    }

    private func stopInputPolling() {
        guard isRunning else { return }
        isRunning = false

        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        displayLink = nil
    }

    private func pollControllerInput() {
        guard let controller = connectedController,
              let gamepad = controller.extendedGamepad else { return }

        onInput?(gamepad)
    }
}