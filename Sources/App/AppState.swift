import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    private let defaults: UserDefaults

    @Published var isActive: Bool = false {
        didSet {
            defaults.set(isActive, forKey: "isActive")
        }
    }

    @Published var isControllerConnected: Bool = false

    @Published var controllerName: String?

    @Published var cursorSpeed: CGFloat = 800 {
        didSet {
            defaults.set(Double(cursorSpeed), forKey: "cursorSpeed")
        }
    }

    @Published var sensitivity: CGFloat = 1.0 {
        didSet {
            defaults.set(Double(sensitivity), forKey: "sensitivity")
        }
    }

    // The cursor settings slider and polling use the same published mapping.
    var deadzone: Float {
        get { buttonMapping.leftStickDeadzone }
        set { buttonMapping.leftStickDeadzone = newValue }
    }

    @Published var buttonMapping: ButtonMapping = ButtonMapping() {
        didSet {
            if let data = try? JSONEncoder().encode(buttonMapping) {
                defaults.set(data, forKey: "buttonMapping")
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isActive = defaults.bool(forKey: "isActive")

        let savedSpeed = defaults.double(forKey: "cursorSpeed")
        cursorSpeed = savedSpeed > 0 ? CGFloat(savedSpeed) : 800

        let savedSensitivity = defaults.double(forKey: "sensitivity")
        sensitivity = savedSensitivity > 0 ? CGFloat(savedSensitivity) : 1.0

        if let data = defaults.data(forKey: "buttonMapping"),
           let mapping = try? JSONDecoder().decode(ButtonMapping.self, from: data) {
            buttonMapping = mapping
        }

        // Older versions saved the visible slider independently of the mapping.
        // Honor that user choice once, persist it, then retire the obsolete key.
        if let legacy = defaults.object(forKey: "deadzone") as? NSNumber {
            let value = legacy.floatValue
            if value.isFinite && (0.05...0.3).contains(value) {
                buttonMapping.leftStickDeadzone = value
                if let data = try? JSONEncoder().encode(buttonMapping) {
                    defaults.set(data, forKey: "buttonMapping")
                    defaults.removeObject(forKey: "deadzone")
                }
            }
        }
    }
}