import Foundation

struct ButtonMapping: Codable, Equatable {
    var leftStickEnabled: Bool = true
    var leftStickDeadzone: Float = 0.1
    var rightStickEnabled: Bool = true
    var rightStickDeadzone: Float = 0.15

    var leftTriggerAction: ControllerAction = .leftClick
    var rightTriggerAction: ControllerAction = .leftDrag
    var leftShoulderAction: ControllerAction = .rightClick
    var rightShoulderAction: ControllerAction = .rightDrag
    var buttonAAction: ControllerAction = .leftClick
    var buttonBAction: ControllerAction = .rightClick
    var buttonXAction: ControllerAction = .middleClick
    var buttonYAction: ControllerAction = .doubleClick
    var dpadUpAction: ControllerAction = .scrollUp
    var dpadDownAction: ControllerAction = .scrollDown
    var dpadLeftAction: ControllerAction = .prevTab
    var dpadRightAction: ControllerAction = .nextTab
    var leftStickPressAction: ControllerAction = .toggleControl
    var rightStickPressAction: ControllerAction = .doubleClick

    private enum CodingKeys: String, CodingKey {
        case leftStickEnabled, leftStickDeadzone, rightStickEnabled, rightStickDeadzone
        case leftTriggerAction, rightTriggerAction, leftShoulderAction, rightShoulderAction
        case buttonAAction, buttonBAction, buttonXAction, buttonYAction
        case dpadUpAction, dpadDownAction, dpadLeftAction, dpadRightAction
        case leftStickPressAction, rightStickPressAction
    }

    init() {}

    /// Decode saved preferences without discarding unrelated customizations when
    /// a release adds, renames or cannot read one field. Missing keys keep their
    /// defaults and stick thresholds are repaired instead of disabling movement.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ButtonMapping()
        func value<T: Decodable>(_ type: T.Type, for key: CodingKeys, fallback: T) -> T {
            (try? container.decodeIfPresent(type, forKey: key)) ?? fallback
        }
        leftStickEnabled = value(Bool.self, for: .leftStickEnabled, fallback: defaults.leftStickEnabled)
        rightStickEnabled = value(Bool.self, for: .rightStickEnabled, fallback: defaults.rightStickEnabled)
        leftStickDeadzone = Self.calibratedDeadzone(
            value(Float.self, for: .leftStickDeadzone, fallback: defaults.leftStickDeadzone),
            fallback: defaults.leftStickDeadzone)
        rightStickDeadzone = Self.calibratedDeadzone(
            value(Float.self, for: .rightStickDeadzone, fallback: defaults.rightStickDeadzone),
            fallback: defaults.rightStickDeadzone)
        leftTriggerAction = value(ControllerAction.self, for: .leftTriggerAction, fallback: defaults.leftTriggerAction)
        rightTriggerAction = value(ControllerAction.self, for: .rightTriggerAction, fallback: defaults.rightTriggerAction)
        leftShoulderAction = value(ControllerAction.self, for: .leftShoulderAction, fallback: defaults.leftShoulderAction)
        rightShoulderAction = value(ControllerAction.self, for: .rightShoulderAction, fallback: defaults.rightShoulderAction)
        buttonAAction = value(ControllerAction.self, for: .buttonAAction, fallback: defaults.buttonAAction)
        buttonBAction = value(ControllerAction.self, for: .buttonBAction, fallback: defaults.buttonBAction)
        buttonXAction = value(ControllerAction.self, for: .buttonXAction, fallback: defaults.buttonXAction)
        buttonYAction = value(ControllerAction.self, for: .buttonYAction, fallback: defaults.buttonYAction)
        dpadUpAction = value(ControllerAction.self, for: .dpadUpAction, fallback: defaults.dpadUpAction)
        dpadDownAction = value(ControllerAction.self, for: .dpadDownAction, fallback: defaults.dpadDownAction)
        dpadLeftAction = value(ControllerAction.self, for: .dpadLeftAction, fallback: defaults.dpadLeftAction)
        dpadRightAction = value(ControllerAction.self, for: .dpadRightAction, fallback: defaults.dpadRightAction)
        leftStickPressAction = value(ControllerAction.self, for: .leftStickPressAction, fallback: defaults.leftStickPressAction)
        rightStickPressAction = value(ControllerAction.self, for: .rightStickPressAction, fallback: defaults.rightStickPressAction)
    }

    /// A saved threshold outside 0...1 would make a stick unusable; keep such a
    /// value from silently disabling cursor control after a corrupted preference.
    private static func calibratedDeadzone(_ value: Float, fallback: Float) -> Float {
        value.isFinite ? min(max(value, 0), 1) : fallback
    }
}

enum ControllerAction: String, Codable, CaseIterable {
    case none
    case leftClick
    case rightClick
    case middleClick
    case doubleClick
    case leftDrag
    case rightDrag
    case scrollUp
    case scrollDown
    case scrollLeft
    case scrollRight
    case prevTab
    case nextTab
    case toggleControl
}
