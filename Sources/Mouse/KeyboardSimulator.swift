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

    private var heldKeys: Set<ArrowKey> = []

    func sendArrowKey(_ key: ArrowKey, press: Bool) {
        guard let keyCode = keyCodes[key] else { return }

        guard let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: press) else { return }
        keyEvent.post(tap: .cghidEventTap)

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

        guard let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: xDelta, wheel2: yDelta, wheel3: 0) else { return }
        scrollEvent.post(tap: .cgSessionEventTap)
    }

    func releaseAllKeys() {
        for key in heldKeys {
            sendArrowKey(key, press: false)
        }
        heldKeys.removeAll()
    }
}