import Foundation
import CoreGraphics
import AppKit

@MainActor
final class ClickDragHandler {
    private var isDragging = false
    private var dragStartLocation: CGPoint = .zero

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
            isDragging = true
            dragStartLocation = mouseLocation
            postMouseEvent(at: clickPoint, type: .leftMouseDown, button: .left)

        case .leftDragEnd:
            isDragging = false
            postMouseEvent(at: clickPoint, type: .leftMouseUp, button: .left)

        case .rightDragStart:
            postMouseEvent(at: clickPoint, type: .rightMouseDown, button: .right)

        case .rightDragEnd:
            postMouseEvent(at: clickPoint, type: .rightMouseUp, button: .right)
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

        downEvent?.post(tap: CGEventTapLocation.cghidEventTap)
        upEvent?.post(tap: CGEventTapLocation.cghidEventTap)
        doubleDownEvent?.post(tap: CGEventTapLocation.cghidEventTap)
        doubleUpEvent?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    private func postMouseEvent(at point: CGPoint, type: CGEventType, button: CGMouseButton) {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: button) else { return }
        event.post(tap: CGEventTapLocation.cghidEventTap)
    }

    private func invertPoint(_ point: CGPoint) -> CGPoint {
        guard let screen = NSScreen.main else { return point }
        return CGPoint(x: point.x, y: screen.frame.height - point.y)
    }
}