import Foundation
import AppKit
import ApplicationServices

@MainActor
final class AccessibilityPermissionHandler: ObservableObject {
    @Published var hasPermission: Bool = false

    init() {
        _ = checkAccessibilityPermission()
    }

    func checkAccessibilityPermission() -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [checkOptPrompt: false] as CFDictionary
        hasPermission = AXIsProcessTrustedWithOptions(options)
        return hasPermission
    }

    func requestAccessibilityPermission() {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [checkOptPrompt: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        Task {
            await pollForPermissionStatus()
        }
    }

    private func pollForPermissionStatus() async {
        for _ in 0..<60 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if checkAccessibilityPermission() {
                return
            }
        }
    }
}