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