import Foundation
import GameController
import Combine

@MainActor
final class ControllerInputHandler: ObservableObject {
    @Published var isActive: Bool = false

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
                .receive(on: DispatchQueue.main)
                .sink { [weak self] mapping in
                    self?.buttonMapping = mapping
                }
                .store(in: &cancellables)

            appState.$isActive
                .receive(on: DispatchQueue.main)
                .sink { [weak self] active in
                    self?.isActive = active
                }
                .store(in: &cancellables)
        }
    }

    func processExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        print("DEBUG: processExtendedGamepad called, isActive=\(isActive)\n"); guard isActive else { return }

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

        processTrigger(
            pressed: gamepad.leftTrigger.isPressed,
            value: gamepad.leftTrigger.value,
            action: buttonMapping.leftTriggerAction,
            buttonId: "leftTrigger"
        )

        processTrigger(
            pressed: gamepad.rightTrigger.isPressed,
            value: gamepad.rightTrigger.value,
            action: buttonMapping.rightTriggerAction,
            buttonId: "rightTrigger"
        )

        processButton(
            pressed: gamepad.leftShoulder.isPressed,
            action: buttonMapping.leftShoulderAction,
            buttonId: "leftShoulder"
        )

        processButton(
            pressed: gamepad.rightShoulder.isPressed,
            action: buttonMapping.rightShoulderAction,
            buttonId: "rightShoulder"
        )

        processButton(
            pressed: gamepad.buttonA.isPressed,
            action: buttonMapping.buttonAAction,
            buttonId: "buttonA"
        )

        processButton(
            pressed: gamepad.buttonB.isPressed,
            action: buttonMapping.buttonBAction,
            buttonId: "buttonB"
        )

        processButton(
            pressed: gamepad.buttonX.isPressed,
            action: buttonMapping.buttonXAction,
            buttonId: "buttonX"
        )

        processButton(
            pressed: gamepad.buttonY.isPressed,
            action: buttonMapping.buttonYAction,
            buttonId: "buttonY"
        )

        processDPad(
            up: gamepad.dpad.up.isPressed,
            down: gamepad.dpad.down.isPressed,
            left: gamepad.dpad.left.isPressed,
            right: gamepad.dpad.right.isPressed
        )

        let leftStickPressed = gamepad.leftThumbstickButton?.isPressed ?? false
        let rightStickPressed = gamepad.rightThumbstickButton?.isPressed ?? false

        processButton(
            pressed: leftStickPressed,
            action: buttonMapping.leftStickPressAction,
            buttonId: "leftStickPress"
        )

        processButton(
            pressed: rightStickPressed,
            action: buttonMapping.rightStickPressAction,
            buttonId: "rightStickPress"
        )
    }

    private func processTrigger(
        pressed: Bool,
        value: Float,
        action: ControllerAction,
        buttonId: String
    ) {
        let key = "trigger_\(buttonId)"
        let wasPressed = previousButtonStates[key] ?? false

        if pressed && !wasPressed {
            handleAction(action, isTrigger: true)
        } else if !pressed && wasPressed && isDragAction(action) {
            handleDragEnd(action)
        }

        previousButtonStates[key] = pressed
    }

    func processButton(pressed: Bool, action: ControllerAction, buttonId: String) {
        let wasPressed = previousButtonStates[buttonId] ?? false

        if pressed && !wasPressed {
            pressedActions[buttonId] = action
            handleAction(action, isTrigger: false)
        } else if !pressed && wasPressed {
            handleButtonRelease(pressedActions.removeValue(forKey: buttonId) ?? action)
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

    private func handleAction(_ action: ControllerAction, isTrigger: Bool) {
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
            appState?.isActive.toggle()
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

    private func isDragAction(_ action: ControllerAction) -> Bool {
        return action == .leftDrag || action == .rightDrag
    }

    func updateButtonMapping(_ mapping: ButtonMapping) {
        self.buttonMapping = mapping
    }
}
