import Foundation
import CoreGraphics
import AppKit

@MainActor
final class ClickDragHandler {
    private let postEvent: (CGEvent) -> Void

    init(postEvent: @escaping (CGEvent) -> Void = { event in
        event.post(tap: .cghidEventTap)
    }) {
        self.postEvent = postEvent
    }

    private var isLeftDragging = false
    private var isRightDragging = false

    enum ClickType {
        case leftClick
        case rightClick
        case middleClick
        case leftDragStart
        case leftDragEnd
        case rightDragStart
        case rightDragEnd
    }

    func handleClick(_ type: ClickType) {
        let mouseLocation = NSEvent.mouseLocation
        let clickPoint = invertPoint(mouseLocation)

        switch type {
        case .leftClick:
            postMouseEvent(at: clickPoint, type: .leftMouseDown, button: .left)
            postMouseEvent(at: clickPoint, type: .leftMouseUp, button: .left)

        case .rightClick:
            postMouseEvent(at: clickPoint, type: .rightMouseDown, button: .right)
            postMouseEvent(at: clickPoint, type: .rightMouseUp, button: .right)

        case .middleClick:
            postMouseEvent(at: clickPoint, type: .otherMouseDown, button: .center)
            postMouseEvent(at: clickPoint, type: .otherMouseUp, button: .center)

        case .leftDragStart:
            isLeftDragging = true
            postMouseEvent(at: clickPoint, type: .leftMouseDown, button: .left)

        case .leftDragEnd:
            isLeftDragging = false
            postMouseEvent(at: clickPoint, type: .leftMouseUp, button: .left)

        case .rightDragStart:
            isRightDragging = true
            postMouseEvent(at: clickPoint, type: .rightMouseDown, button: .right)

        case .rightDragEnd:
            isRightDragging = false
            postMouseEvent(at: clickPoint, type: .rightMouseUp, button: .right)
        }
    }

    // Warping the cursor does not post mouse events. A held controller drag
    // also needs movement events at the same constrained Quartz position.
    func handleDragMovement(at point: CGPoint) {
        if isLeftDragging {
            postMouseEvent(at: point, type: .leftMouseDragged, button: .left)
        }
        if isRightDragging {
            postMouseEvent(at: point, type: .rightMouseDragged, button: .right)
        }
    }

    func handleDoubleClick() {
        let mouseLocation = NSEvent.mouseLocation
        let clickPoint = invertPoint(mouseLocation)

        let downEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: clickPoint,
            mouseButton: .left
        )
        let upEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: clickPoint,
            mouseButton: .left
        )
        let doubleDownEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: clickPoint,
            mouseButton: .left
        )
        let doubleUpEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: clickPoint,
            mouseButton: .left
        )

        guard let downEvent, let upEvent, let doubleDownEvent, let doubleUpEvent else { return }
        for (event, count) in [(downEvent, Int64(1)), (upEvent, 1),
                               (doubleDownEvent, 2), (doubleUpEvent, 2)] {
            event.setIntegerValueField(.mouseEventClickState, value: count)
            postEvent(event)
        }
    }

    private func postMouseEvent(at point: CGPoint, type: CGEventType, button: CGMouseButton) {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: button) else { return }
        postEvent(event)
    }

    private func invertPoint(_ point: CGPoint) -> CGPoint {
        guard let screen = NSScreen.screens.first else { return point }
        return CGPoint(x: point.x, y: screen.frame.maxY - point.y)
    }
}