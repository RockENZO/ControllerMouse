import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isActive: Bool = false {
        didSet {
            UserDefaults.standard.set(isActive, forKey: "isActive")
        }
    }

    @Published var isControllerConnected: Bool = false

    @Published var controllerName: String?

    @Published var cursorSpeed: CGFloat = 800 {
        didSet {
            UserDefaults.standard.set(Double(cursorSpeed), forKey: "cursorSpeed")
        }
    }

    @Published var sensitivity: CGFloat = 1.0 {
        didSet {
            UserDefaults.standard.set(Double(sensitivity), forKey: "sensitivity")
        }
    }

    @Published var deadzone: Float = 0.1 {
        didSet {
            UserDefaults.standard.set(Double(deadzone), forKey: "deadzone")
        }
    }

    @Published var buttonMapping: ButtonMapping = ButtonMapping() {
        didSet {
            if let data = try? JSONEncoder().encode(buttonMapping) {
                UserDefaults.standard.set(data, forKey: "buttonMapping")
            }
        }
    }

    init() {
        isActive = UserDefaults.standard.bool(forKey: "isActive")

        let savedSpeed = UserDefaults.standard.double(forKey: "cursorSpeed")
        cursorSpeed = savedSpeed > 0 ? CGFloat(savedSpeed) : 800

        let savedSensitivity = UserDefaults.standard.double(forKey: "sensitivity")
        sensitivity = savedSensitivity > 0 ? CGFloat(savedSensitivity) : 1.0

        let savedDeadzone = UserDefaults.standard.double(forKey: "deadzone")
        deadzone = savedDeadzone > 0 ? Float(savedDeadzone) : 0.1

        if let data = UserDefaults.standard.data(forKey: "buttonMapping"),
           let mapping = try? JSONDecoder().decode(ButtonMapping.self, from: data) {
            buttonMapping = mapping
        }
    }
}