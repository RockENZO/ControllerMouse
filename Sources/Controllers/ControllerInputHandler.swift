import Foundation
import GameController
import Combine

@MainActor
final class ControllerInputHandler: ObservableObject {
    @Published var isActive: Bool = false {
        didSet {
            if !isActive { releaseHeldInputs() }
        }
    }

    private let mouseController: MouseController
    private let clickDragHandler: ClickDragHandler
    private let keyboardSimulator: KeyboardSimulator
    private var buttonMapping: ButtonMapping
    private var previousButtonStates: [String: Bool] = [:]
    private var pressedActions: [String: ControllerAction] = [:]
    private weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()

    init(
        mouseController: MouseController,
        clickDragHandler: ClickDragHandler,
        keyboardSimulator: KeyboardSimulator,
        appState: AppState? = nil,
        buttonMapping: ButtonMapping = ButtonMapping()
    ) {
        self.mouseController = mouseController
        self.clickDragHandler = clickDragHandler
        self.keyboardSimulator = keyboardSimulator
        self.appState = appState
        self.buttonMapping = buttonMapping

        if let appState = appState {
            appState.$buttonMapping
                .sink { [weak self] mapping in
                    self?.buttonMapping = mapping
                }
                .store(in: &cancellables)

            appState.$isActive
                .sink { [weak self] active in
                    self?.isActive = active
                }
                .store(in: &cancellables)
        }
    }

    func processExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        let inputs: [(String, Bool, ControllerAction)] = [
            ("leftTrigger", gamepad.leftTrigger.isPressed, buttonMapping.leftTriggerAction),
            ("rightTrigger", gamepad.rightTrigger.isPressed, buttonMapping.rightTriggerAction),
            ("leftShoulder", gamepad.leftShoulder.isPressed, buttonMapping.leftShoulderAction),
            ("rightShoulder", gamepad.rightShoulder.isPressed, buttonMapping.rightShoulderAction),
            ("buttonA", gamepad.buttonA.isPressed, buttonMapping.buttonAAction),
            ("buttonB", gamepad.buttonB.isPressed, buttonMapping.buttonBAction),
            ("buttonX", gamepad.buttonX.isPressed, buttonMapping.buttonXAction),
            ("buttonY", gamepad.buttonY.isPressed, buttonMapping.buttonYAction),
            ("dpad_up", gamepad.dpad.up.isPressed, buttonMapping.dpadUpAction),
            ("dpad_down", gamepad.dpad.down.isPressed, buttonMapping.dpadDownAction),
            ("dpad_left", gamepad.dpad.left.isPressed, buttonMapping.dpadLeftAction),
            ("dpad_right", gamepad.dpad.right.isPressed, buttonMapping.dpadRightAction),
            ("leftStickPress", gamepad.leftThumbstickButton?.isPressed ?? false, buttonMapping.leftStickPressAction),
            ("rightStickPress", gamepad.rightThumbstickButton?.isPressed ?? false, buttonMapping.rightStickPressAction),
        ]
        processButtonFrame(inputs)
        guard isActive else { return }

        let dx = gamepad.leftThumbstick.xAxis.value
        let dy = gamepad.leftThumbstick.yAxis.value

        let magnitude = sqrt(dx * dx + dy * dy)
        if magnitude > buttonMapping.leftStickDeadzone {
            mouseController.updateCursorPosition(dx: Float(dx), dy: Float(-dy), timestamp: CACurrentMediaTime())
        }

        if buttonMapping.rightStickEnabled {
            let rx = gamepad.rightThumbstick.xAxis.value
            let ry = gamepad.rightThumbstick.yAxis.value
            let rightMagnitude = sqrt(rx * rx + ry * ry)
            if rightMagnitude > buttonMapping.rightStickDeadzone {
                mouseController.updateCursorPosition(dx: Float(rx), dy: Float(-ry), timestamp: CACurrentMediaTime())
            }
        }

    }

    // Poll toggle inputs even when cursor control is disabled. Ordinary inputs
    // still update their edge state while disabled so held presses cannot replay.
    func processButtonFrame(_ inputs: [(String, Bool, ControllerAction)]) {
        for (id, pressed, action) in inputs where action == .toggleControl {
            processButton(pressed: pressed, action: action, buttonId: id)
        }
        for (id, pressed, action) in inputs where action != .toggleControl {
            processButton(pressed: pressed, action: action, buttonId: id)
        }
    }

    func processButton(pressed: Bool, action: ControllerAction, buttonId: String) {
        let wasPressed = previousButtonStates[buttonId] ?? false

        if pressed && !wasPressed && (isActive || action == .toggleControl) {
            pressedActions[buttonId] = action
            handleAction(action)
        } else if !pressed && wasPressed {
            if let heldAction = pressedActions.removeValue(forKey: buttonId) {
                handleButtonRelease(heldAction)
            }
        }

        previousButtonStates[buttonId] = pressed
    }

    // Internal so the input mapping can be verified without a physical controller.
    func processDPad(up: Bool, down: Bool, left: Bool, right: Bool) {
        processButton(pressed: up, action: buttonMapping.dpadUpAction, buttonId: "dpad_up")
        processButton(pressed: down, action: buttonMapping.dpadDownAction, buttonId: "dpad_down")
        processButton(pressed: left, action: buttonMapping.dpadLeftAction, buttonId: "dpad_left")
        processButton(pressed: right, action: buttonMapping.dpadRightAction, buttonId: "dpad_right")
    }

    private func handleAction(_ action: ControllerAction) {
        switch action {
        case .leftClick:
            clickDragHandler.handleClick(.leftClick)
        case .rightClick:
            clickDragHandler.handleClick(.rightClick)
        case .middleClick:
            clickDragHandler.handleClick(.middleClick)
        case .doubleClick:
            clickDragHandler.handleDoubleClick()
        case .leftDrag:
            clickDragHandler.handleClick(.leftDragStart)
        case .rightDrag:
            clickDragHandler.handleClick(.rightDragStart)
        case .scrollUp:
            keyboardSimulator.sendScroll(.up, press: true)
        case .scrollDown:
            keyboardSimulator.sendScroll(.down, press: true)
        case .scrollLeft:
            keyboardSimulator.sendScroll(.left, press: true)
        case .scrollRight:
            keyboardSimulator.sendScroll(.right, press: true)
        case .prevTab:
            keyboardSimulator.sendTabSwitch(previous: true)
        case .nextTab:
            keyboardSimulator.sendTabSwitch(previous: false)
        case .toggleControl:
            isActive.toggle()
            appState?.isActive = isActive
        default:
            break
        }
    }

    private func handleDragEnd(_ action: ControllerAction) {
        switch action {
        case .leftDrag:
            clickDragHandler.handleClick(.leftDragEnd)
        case .rightDrag:
            clickDragHandler.handleClick(.rightDragEnd)
        default:
            break
        }
    }

    private func handleButtonRelease(_ action: ControllerAction) {
        handleDragEnd(action)
    }

    private func releaseHeldInputs() {
        for action in Set(pressedActions.values) { handleDragEnd(action) }
        pressedActions.removeAll()
        keyboardSimulator.releaseAllKeys()
        mouseController.stop()
    }

    // A disconnected/replaced controller must not leave down events or old
    // press edges behind; the next device starts with a fresh input state.
    func resetInputState() {
        releaseHeldInputs()
        previousButtonStates.removeAll()
    }

    func updateButtonMapping(_ mapping: ButtonMapping) {
        self.buttonMapping = mapping
    }
}
