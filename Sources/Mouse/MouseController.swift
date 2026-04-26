import Foundation
import CoreGraphics
import AppKit

@MainActor
final class MouseController {
    private let appState: AppState
    private var lastUpdateTime: CFTimeInterval = 0

    init(appState: AppState) {
        self.appState = appState
    }

    func updateCursorPosition(dx: Float, dy: Float, timestamp: CFTimeInterval) {
        let deltaTime = timestamp - lastUpdateTime
        lastUpdateTime = timestamp

        guard deltaTime > 0 && deltaTime < 0.1 else { return }

        let scaledDeltaX = CGFloat(dx) * appState.cursorSpeed * appState.sensitivity * CGFloat(deltaTime)
        let scaledDeltaY = CGFloat(dy) * appState.cursorSpeed * appState.sensitivity * CGFloat(deltaTime)

        let currentPos = NSEvent.mouseLocation
        var newX = currentPos.x + scaledDeltaX
        var newY = currentPos.y + scaledDeltaY

        guard let screen = NSScreen.main else { return }

        // Clamp to screen bounds
        let minX: CGFloat = 0
        let maxX = screen.frame.width
        let minY: CGFloat = 0
        let maxY = screen.frame.height

        newX = max(minX, min(newX, maxX))
        newY = max(minY, min(newY, maxY))

        CGWarpMouseCursorPosition(CGPoint(x: newX, y: newY))
    }

    func stop() {
        // Cleanup if needed
    }
}