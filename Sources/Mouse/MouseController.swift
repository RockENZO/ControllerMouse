import Foundation
import CoreGraphics
import AppKit

@MainActor
final class MouseController {
    private let appState: AppState
    private var lastUpdateTime: CFTimeInterval = 0

    private let cursorLocation: () -> CGPoint?
    private let screenBounds: () -> [CGRect]
    private let warpCursor: (CGPoint) -> Void

    init(appState: AppState,
         cursorLocation: @escaping () -> CGPoint? = { CGEvent(source: nil)?.location },
         screenBounds: @escaping () -> [CGRect] = {
             let top = NSScreen.screens.first?.frame.maxY ?? 0
             return NSScreen.screens.map {
                 CGRect(x: $0.frame.minX, y: top - $0.frame.maxY,
                        width: $0.frame.width, height: $0.frame.height)
             }
         },
         warpCursor: @escaping (CGPoint) -> Void = { CGWarpMouseCursorPosition($0) }) {
        self.appState = appState
        self.cursorLocation = cursorLocation
        self.screenBounds = screenBounds
        self.warpCursor = warpCursor
    }

    static func constrained(_ point: CGPoint, to bounds: [CGRect]) -> CGPoint? {
        let displays = bounds.filter { $0.width > 0 && $0.height > 0 }
        if displays.contains(where: { $0.contains(point) }) { return point }
        return displays.map { rect in
            CGPoint(x: max(rect.minX, min(point.x, rect.maxX - 1)),
                    y: max(rect.minY, min(point.y, rect.maxY - 1)))
        }.min { a, b in
            hypot(a.x - point.x, a.y - point.y) < hypot(b.x - point.x, b.y - point.y)
        }
    }

    @discardableResult
    func updateCursorPosition(dx: Float, dy: Float, timestamp: CFTimeInterval) -> CGPoint? {
        let deltaTime = timestamp - lastUpdateTime
        lastUpdateTime = timestamp

        guard deltaTime > 0 && deltaTime < 0.1 else { return nil }

        let scaledDeltaX = CGFloat(dx) * appState.cursorSpeed * appState.sensitivity * CGFloat(deltaTime)
        let scaledDeltaY = CGFloat(dy) * appState.cursorSpeed * appState.sensitivity * CGFloat(deltaTime)

        guard dx != 0 || dy != 0, let current = cursorLocation(),
              let target = Self.constrained(CGPoint(x: current.x + scaledDeltaX,
                                                    y: current.y + scaledDeltaY), to: screenBounds()), target != current else { return nil }
        warpCursor(target)
        return target
    }

    func stop() {
        lastUpdateTime = 0
    }
}