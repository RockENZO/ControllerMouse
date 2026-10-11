import Foundation
import CoreGraphics

@main
struct ControllerMappingTests {
    @MainActor static func main() {
        var events: [CGEvent] = []
        let keyboard = KeyboardSimulator { event, _ in events.append(event) }
        let clicks = ClickDragHandler { event in events.append(event) }
        let handler = ControllerInputHandler(
            mouseController: MouseController(appState: AppState()),
            clickDragHandler: clicks,
            keyboardSimulator: keyboard
        )
        handler.isActive = true
        func dpad(_ left: Bool = false, _ right: Bool = false) {
            handler.processDPad(up: false, down: false, left: left, right: right)
        }
        func keyCodes() -> [Int64] { events.map { $0.getIntegerValueField(.keyboardEventKeycode) } }

        dpad(true)
        precondition(keyCodes() == [59, 56, 48, 48, 56, 59], "Previous tab must balance Control/Shift/Tab")
        precondition(events[2].flags.contains([.maskControl, .maskShift]))
        precondition(events.last!.flags.isEmpty, "Modifiers must be released")
        let count = events.count
        dpad(true)
        precondition(events.count == count, "Held D-pad must not repeat the shortcut")
        dpad()
        precondition(events.count == count, "Release must not emit an arrow")
        events.removeAll()
        dpad(false, true)
        precondition(keyCodes() == [59, 48, 48, 59], "Next tab must balance Control/Tab")
        precondition(events[1].flags == .maskControl)
        dpad()

        var mapping = ButtonMapping()
        mapping.dpadLeftAction = .none
        handler.updateButtonMapping(mapping)
        events.removeAll()
        dpad(true); dpad()
        precondition(events.isEmpty, "Disabled input must produce no events")

        for (action, axis1, axis2) in [
            (ControllerAction.scrollUp, Int64(3), Int64(0)),
            (.scrollDown, -3, 0), (.scrollLeft, 0, -3), (.scrollRight, 0, 3)
        ] {
            mapping.dpadLeftAction = action
            handler.updateButtonMapping(mapping)
            events.removeAll()
            dpad(true); dpad(true); dpad()
            precondition(events.count == 1 && events[0].type == .scrollWheel)
            precondition(events[0].getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == axis1)
            precondition(events[0].getIntegerValueField(.scrollWheelEventPointDeltaAxis2) == axis2)
        }

        mapping.dpadLeftAction = .leftDrag
        handler.updateButtonMapping(mapping)
        events.removeAll()
        dpad(true)
        mapping.dpadLeftAction = .none
        handler.updateButtonMapping(mapping)
        dpad()
        precondition(events.map { $0.type } == [.leftMouseDown, .leftMouseUp], "Remapping while held must release the original drag")

        events.removeAll()
        handler.processButton(pressed: true, action: .nextTab, buttonId: "buttonA")
        handler.processButton(pressed: true, action: .nextTab, buttonId: "buttonA")
        handler.processButton(pressed: false, action: .nextTab, buttonId: "buttonA")
        precondition(keyCodes() == [59, 48, 48, 59], "Face buttons must honor tab mappings once per press")

        events.removeAll()
        handler.processButton(pressed: true, action: .rightDrag, buttonId: "rightShoulder")
        handler.processButton(pressed: false, action: .rightDrag, buttonId: "rightShoulder")
        precondition(events.map { $0.type } == [.rightMouseDown, .rightMouseUp], "Shoulder drag must release")
        // 1: a toggle can disable, remain held without oscillation, and reenable.
        handler.resetInputState()
        handler.processButtonFrame([("toggle", true, .toggleControl)])
        precondition(!handler.isActive)
        handler.processButtonFrame([("toggle", true, .toggleControl)])
        precondition(!handler.isActive)
        handler.processButtonFrame([("toggle", false, .toggleControl)])
        handler.processButtonFrame([("toggle", true, .toggleControl)])
        precondition(handler.isActive)
        handler.processButtonFrame([("toggle", false, .toggleControl)])

        // 2: inactive presses are latched, never replayed after reactivation.
        handler.isActive = false
        events.removeAll()
        handler.processButtonFrame([("buttonA", true, .nextTab)])
        precondition(events.isEmpty)
        handler.processButtonFrame([("toggle", true, .toggleControl), ("buttonA", true, .nextTab)])
        precondition(handler.isActive && events.isEmpty)
        handler.processButtonFrame([("buttonA", false, .nextTab)])
        handler.processButtonFrame([("buttonA", true, .nextTab)])
        precondition(keyCodes() == [59, 48, 48, 59])
        handler.resetInputState()

        // 3: disabling releases both mouse buttons and a held keyboard key.
        events.removeAll()
        handler.processButton(pressed: true, action: .leftDrag, buttonId: "leftTrigger")
        handler.processButton(pressed: true, action: .rightDrag, buttonId: "rightTrigger")
        keyboard.sendArrowKey(.up, press: true)
        handler.isActive = false
        precondition(events.filter { $0.type == .leftMouseUp }.count == 1)
        precondition(events.filter { $0.type == .rightMouseUp }.count == 1)
        precondition(events.filter { $0.type == .keyUp }.count == 1)
        let releasedCount = events.count
        handler.resetInputState()
        precondition(events.count == releasedCount, "Cleanup must be idempotent")

        // 4: disconnect/reset releases a drag and permits the next device press.
        handler.isActive = true
        events.removeAll()
        handler.processButton(pressed: true, action: .leftDrag, buttonId: "leftTrigger")
        handler.resetInputState()
        handler.processButton(pressed: true, action: .leftDrag, buttonId: "leftTrigger")
        handler.processButton(pressed: false, action: .none, buttonId: "leftTrigger")
        precondition(events.map { $0.type } == [.leftMouseDown, .leftMouseUp, .leftMouseDown, .leftMouseUp])

        // 5: toggling off wins over an ordinary press in the same poll.
        handler.resetInputState()
        events.removeAll()
        handler.processButtonFrame([("buttonA", true, .leftClick), ("toggle", true, .toggleControl)])
        precondition(!handler.isActive && events.isEmpty)

        // 6: a D-pad toggle also works while inactive.
        handler.resetInputState()
        mapping.dpadLeftAction = .toggleControl
        handler.updateButtonMapping(mapping)
        dpad(true)
        precondition(handler.isActive)
        dpad()
        handler.resetInputState()
        print("Passed 16 controller mapping/lifecycle scenarios; no desktop events posted.")
    }
}
