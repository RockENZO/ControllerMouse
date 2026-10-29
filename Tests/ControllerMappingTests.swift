import Foundation
import CoreGraphics

@main
struct ControllerMappingTests {
    @MainActor static func main() {
        let suite = "ControllerMouseTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var events: [CGEvent] = []
        let keyboard = KeyboardSimulator { event, _ in events.append(event) }
        let clicks = ClickDragHandler { event in events.append(event) }
        let handler = ControllerInputHandler(
            mouseController: MouseController(appState: AppState(defaults: defaults)),
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
        events.removeAll()
        clicks.handleDoubleClick()
        precondition(events.map { $0.type } == [.leftMouseDown, .leftMouseUp, .leftMouseDown, .leftMouseUp])
        precondition(events.map { $0.getIntegerValueField(.mouseEventClickState) } == [1,1,2,2],
                     "Double-click events must carry single then double click counts")
        for action in [ControllerAction.leftDrag, .rightDrag] {
            handler.resetInputState()
            events.removeAll()
            handler.processButton(pressed: true, action: action, buttonId: "first")
            handler.processButton(pressed: true, action: action, buttonId: "second")
            precondition(events.count == 1, "Shared drag must press the mouse only once")
            handler.processButton(pressed: false, action: .none, buttonId: "first")
            precondition(events.count == 1, "Drag must remain down while another mapped button is held")
            handler.processButton(pressed: false, action: .none, buttonId: "second")
            precondition(events.count == 2, "Last owner must release the drag")
        }
        handler.resetInputState()
        events.removeAll()
        handler.processButton(pressed: true, action: .leftDrag, buttonId: "first")
        handler.processButton(pressed: true, action: .leftDrag, buttonId: "second")
        handler.isActive = false
        precondition(events.map { $0.type } == [.leftMouseDown, .leftMouseUp], "Disable must release a shared drag once")
        handler.isActive = true
        for action in [ControllerAction.leftDrag, .rightDrag] {
            for reverseOrder in [false, true] {
                handler.resetInputState()
                events.removeAll()
                handler.processButtonFrame([("old", true, action), ("new", false, action)])
                let handoff: [(String, Bool, ControllerAction)] = [("old", false, action), ("new", true, action)]
                handler.processButtonFrame(reverseOrder ? Array(handoff.reversed()) : handoff)
                precondition(events.count == 1, "A same-frame drag handoff must not emit mouse-up/down")
                handler.processButtonFrame([("old", false, action), ("new", false, action)])
                precondition(events.count == 2, "Final frame must release exactly once")
            }
        }
        let state = AppState(defaults: defaults)
        let originalSpeed = state.cursorSpeed
        let originalSensitivity = state.sensitivity
        defer { state.cursorSpeed = originalSpeed; state.sensitivity = originalSensitivity }
        state.cursorSpeed = 100
        state.sensitivity = 1
        var cursor = CGPoint(x: 10, y: 20)
        var warps: [CGPoint] = []
        let mouse = MouseController(appState: state, cursorLocation: { cursor },
            screenBounds: { [CGRect(x: -100, y: -100, width: 300, height: 300)] },
            warpCursor: { cursor = $0; warps.append($0) })
        let sticks = ControllerInputHandler(mouseController: mouse, clickDragHandler: clicks,
                                            keyboardSimulator: keyboard)
        sticks.isActive = true
        var axes = ButtonMapping()
        axes.leftStickEnabled = false; axes.rightStickEnabled = false
        sticks.updateButtonMapping(axes)
        sticks.processStickFrame(leftX: 1, leftY: 1, rightX: 1, rightY: 1, timestamp: 1)
        sticks.processStickFrame(leftX: 1, leftY: 1, rightX: 1, rightY: 1, timestamp: 1.01)
        precondition(warps.isEmpty, "Disabled sticks must not move")
        axes.leftStickEnabled = true
        sticks.updateButtonMapping(axes)
        sticks.processStickFrame(leftX: 0, leftY: 1, rightX: 1, rightY: 0, timestamp: 1.02)
        precondition(abs(cursor.y - 19) < 0.0001 && cursor.x == 10, "Up must move upward in Quartz coordinates; disabled right stick is ignored")
        axes.rightStickEnabled = true
        sticks.updateButtonMapping(axes)
        sticks.processStickFrame(leftX: 1, leftY: 0, rightX: 1, rightY: 0, timestamp: 1.03)
        precondition(abs(cursor.x - 11) < 0.0001 && warps.count == 2, "Both sticks must share one bounded movement per frame")
        let screens = [CGRect(x: 0, y: 0, width: 100, height: 100),
                       CGRect(x: -100, y: 0, width: 100, height: 100),
                       CGRect(x: 0, y: -100, width: 100, height: 100)]
        precondition(MouseController.constrained(CGPoint(x: -50, y: 20), to: screens) == CGPoint(x: -50, y: 20))
        precondition(MouseController.constrained(CGPoint(x: 20, y: -50), to: screens) == CGPoint(x: 20, y: -50))
        precondition(MouseController.constrained(CGPoint(x: 250, y: 20), to: screens) == CGPoint(x: 99, y: 20))
        precondition(MouseController.constrained(CGPoint(x: 20, y: 20), to: []) == nil)
        mouse.stop()
        sticks.processStickFrame(leftX: 1, leftY: 0, rightX: 0, rightY: 0, timestamp: 5)
        precondition(warps.count == 2, "Resume must not jump across a stale interval")
        // Cursor movement must reach focused apps as drag events, not only a warp.
        for (action, down, dragged, up, button) in [
            (ControllerAction.leftDrag, CGEventType.leftMouseDown, CGEventType.leftMouseDragged,
             CGEventType.leftMouseUp, Int64(0)),
            (.rightDrag, .rightMouseDown, .rightMouseDragged, .rightMouseUp, 1)
        ] {
            sticks.resetInputState()
            sticks.isActive = true
            events.removeAll()
            sticks.processButton(pressed: true, action: action, buttonId: "first")
            sticks.processButton(pressed: true, action: action, buttonId: "second")
            sticks.processStickFrame(leftX: 1, leftY: 0, rightX: 0, rightY: 0, timestamp: 10)
            precondition(events.map { $0.type } == [down], "First movement sample only establishes the clock")
            sticks.processStickFrame(leftX: 1, leftY: 0, rightX: 0, rightY: 0, timestamp: 10.01)
            precondition(events.map { $0.type } == [down, dragged], "Warp must be accompanied by a drag event")
            precondition(events.last!.location == cursor, "Drag event must use the constrained Quartz cursor position")
            precondition(events.last!.getIntegerValueField(.mouseEventButtonNumber) == button)
            sticks.processButton(pressed: false, action: .none, buttonId: "first")
            sticks.processStickFrame(leftX: 1, leftY: 0, rightX: 0, rightY: 0, timestamp: 10.02)
            precondition(events.map { $0.type } == [down, dragged, dragged], "Remaining drag owner must keep receiving movement")
            sticks.processButton(pressed: false, action: .none, buttonId: "second")
            sticks.processStickFrame(leftX: 1, leftY: 0, rightX: 0, rightY: 0, timestamp: 10.03)
            precondition(events.map { $0.type } == [down, dragged, dragged, up], "Released drag must stop producing drag movement")
            sticks.processButton(pressed: true, action: action, buttonId: "first")
            sticks.isActive = false
            let releasedCount = events.count
            sticks.processStickFrame(leftX: 1, leftY: 0, rightX: 0, rightY: 0, timestamp: 10.04)
            precondition(events.count == releasedCount, "Disabled control must not send drag movement")
        }
        sticks.isActive = true
        sticks.resetInputState()
        events.removeAll()
        sticks.processButton(pressed: true, action: .leftDrag, buttonId: "left")
        sticks.processButton(pressed: true, action: .rightDrag, buttonId: "right")
        sticks.processStickFrame(leftX: 1, leftY: 0, rightX: 0, rightY: 0, timestamp: 20)
        sticks.processStickFrame(leftX: 1, leftY: 0, rightX: 0, rightY: 0, timestamp: 20.01)
        precondition(events.map { $0.type } == [.leftMouseDown, .rightMouseDown, .leftMouseDragged, .rightMouseDragged])
        sticks.resetInputState()
        events.removeAll()
        sticks.processStickFrame(leftX: 1, leftY: 0, rightX: 0, rightY: 0, timestamp: 21)
        sticks.processStickFrame(leftX: 0, leftY: 0, rightX: 0, rightY: 0, timestamp: 21.01)
        precondition(events.isEmpty, "Reset and stationary movement must not resurrect drag state")
        // The actual AppState -> Combine -> input path must follow slider changes.
        defaults.removePersistentDomain(forName: suite)
        let settings = AppState(defaults: defaults)
        var settingsWarps: [CGPoint] = []
        let settingsMouse = MouseController(appState: settings,
            cursorLocation: { CGPoint(x: 50, y: 50) },
            screenBounds: { [CGRect(x: 0, y: 0, width: 100, height: 100)] },
            warpCursor: { settingsWarps.append($0) })
        let settingsInput = ControllerInputHandler(mouseController: settingsMouse,
            clickDragHandler: clicks, keyboardSimulator: keyboard, appState: settings,
            buttonMapping: settings.buttonMapping)
        settings.isActive = true
        settings.deadzone = 0.3
        settingsInput.processStickFrame(leftX: 0.2, leftY: 0, rightX: 0, rightY: 0, timestamp: 1)
        settingsInput.processStickFrame(leftX: 0.2, leftY: 0, rightX: 0, rightY: 0, timestamp: 1.01)
        precondition(settingsWarps.isEmpty, "Slider deadzone must suppress the left stick immediately")
        settings.deadzone = 0.05
        settingsInput.processStickFrame(leftX: 0.2, leftY: 0, rightX: 0, rightY: 0, timestamp: 1.02)
        precondition(settingsWarps.count == 1, "Lowering the slider must immediately allow movement")
        precondition(settings.buttonMapping.rightStickDeadzone == 0.15, "Left slider must preserve the right stick threshold")
        precondition(AppState(defaults: defaults).deadzone == 0.05, "Slider must survive relaunch")
        // Migrate the old visible setting, preserving unrelated customizations.
        var savedMapping = settings.buttonMapping
        savedMapping.buttonAAction = .rightClick
        savedMapping.rightStickDeadzone = 0.25
        defaults.set(try! JSONEncoder().encode(savedMapping), forKey: "buttonMapping")
        defaults.set(0.28, forKey: "deadzone")
        let migrated = AppState(defaults: defaults)
        precondition(abs(migrated.deadzone - 0.28) < 0.0001)
        precondition(migrated.buttonMapping.buttonAAction == .rightClick && migrated.buttonMapping.rightStickDeadzone == 0.25)
        precondition(defaults.object(forKey: "deadzone") == nil, "Legacy key must be retired after persistence")
        migrated.deadzone = 0.12
        precondition(AppState(defaults: defaults).deadzone == 0.12, "Legacy migration must not replay over later edits")
        defaults.removePersistentDomain(forName: suite)
        defaults.set(Double(Float(0.3)), forKey: "deadzone")
        precondition(AppState(defaults: defaults).deadzone == 0.3, "Previously saved Float maximum must migrate despite Double roundoff")
        defaults.removePersistentDomain(forName: suite)
        defaults.set(5.0, forKey: "deadzone")
        precondition(AppState(defaults: defaults).deadzone == 0.1, "Invalid legacy values must not disable cursor movement")
        print("Passed deadzone live-update, relaunch and migration checks; 24 mapping/lifecycle scenarios plus cursor geometry, stick integration and drag-motion checks; no desktop events posted.")
    }
}
