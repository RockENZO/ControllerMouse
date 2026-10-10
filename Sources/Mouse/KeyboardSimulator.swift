import Foundation
import CoreGraphics
import AppKit

@MainActor
final class KeyboardSimulator {
    enum ArrowKey: String {
        case up, down, left, right
    }

    private let keyCodes: [ArrowKey: CGKeyCode] = [
        .up: 126,
        .down: 125,
        .left: 123,
        .right: 124
    ]

    private let postEvent: (CGEvent, CGEventTapLocation) -> Void

    init(postEvent: @escaping (CGEvent, CGEventTapLocation) -> Void = { event, tap in
        event.post(tap: tap)
    }) {
        self.postEvent = postEvent
    }

    private var heldKeys: Set<ArrowKey> = []

    func sendArrowKey(_ key: ArrowKey, press: Bool) {
        guard let keyCode = keyCodes[key] else { return }

        guard let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: press) else { return }
        postEvent(keyEvent, .cghidEventTap)

        if press {
            heldKeys.insert(key)
        } else {
            heldKeys.remove(key)
        }
    }

    func sendScroll(_ direction: ArrowKey, press: Bool) {
        guard press else { return }

        let scrollChars: [ArrowKey: (Int32, Int32)] = [
            .up: (0, 3),
            .down: (0, -3),
            .left: (-3, 0),
            .right: (3, 0)
        ]

        guard let (xDelta, yDelta) = scrollChars[direction] else { return }

        guard let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: yDelta, wheel2: xDelta, wheel3: 0) else { return }
        postEvent(scrollEvent, .cgSessionEventTap)
    }

    /// Standard Control-Tab / Control-Shift-Tab shortcuts; support depends on the focused app.
    func sendTabSwitch(previous: Bool) {
        let modifiers: [(CGKeyCode, CGEventFlags)] = previous
            ? [(59, .maskControl), (56, [.maskControl, .maskShift])]
            : [(59, .maskControl)]
        // Prepare the full sequence before posting so an allocation failure cannot
        // leave only the modifier-down events on the desktop.
        var events: [CGEvent] = []
        for (code, flags) in modifiers {
            guard let event = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true) else { return }
            event.flags = flags
            events.append(event)
        }
        let flags: CGEventFlags = previous ? [.maskControl, .maskShift] : .maskControl
        for down in [true, false] {
            guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 48, keyDown: down) else { return }
            event.flags = flags
            events.append(event)
        }
        for (index, modifier) in modifiers.enumerated().reversed() {
            guard let event = CGEvent(keyboardEventSource: nil, virtualKey: modifier.0, keyDown: false) else { return }
            event.flags = index == 0 ? [] : .maskControl
            events.append(event)
        }
        for event in events { postEvent(event, .cghidEventTap) }
    }

    func releaseAllKeys() {
        for key in heldKeys {
            sendArrowKey(key, press: false)
        }
        heldKeys.removeAll()
    }
}