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
        print("Passed 10 controller mapping scenarios; no desktop events posted.")
    }
}
