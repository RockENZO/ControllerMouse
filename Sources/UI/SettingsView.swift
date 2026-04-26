import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var inputHandler: ControllerInputHandler
    @ObservedObject var accessibilityHandler: AccessibilityPermissionHandler
    @State private var cursorSpeed: Double = 800
    @State private var sensitivity: Double = 1.0
    @State private var deadzone: Double = 0.1
    @State private var showEditMapping: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusSection
                    permissionsSection
                    cursorSection
                    buttonMappingSection
                    dpadSection
                }
                .padding()
            }
            Divider()
            footerView
        }
        .frame(width: 320, height: 480)
        .sheet(isPresented: $showEditMapping) {
            EditButtonMappingSheet(appState: appState)
        }
        .onAppear {
            cursorSpeed = appState.cursorSpeed
            sensitivity = appState.sensitivity
            deadzone = Double(appState.deadzone)
        }
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "gamecontroller.fill")
                .font(.title2)
            Text("ControllerMouse")
                .font(.headline)
            Spacer()
            Toggle("", isOn: $appState.isActive)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var statusSection: some View {
        Section {
            HStack {
                Circle()
                    .fill(appState.isControllerConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(appState.isControllerConnected ? "Controller Connected" : "No Controller")
                    .foregroundColor(.secondary)
                Spacer()
                Text(appState.controllerName ?? "")
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        } header: {
            Text("Status")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var permissionsSection: some View {
        Section {
            HStack {
                Image(systemName: accessibilityHandler.hasPermission ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(accessibilityHandler.hasPermission ? .green : .orange)
                Text("Accessibility")
                    .font(.body)
                Spacer()
                if !accessibilityHandler.hasPermission {
                    Button("Enable") {
                        accessibilityHandler.requestAccessibilityPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    Text("Granted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Permissions")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var cursorSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Speed")
                    Slider(value: $cursorSpeed, in: 200...2000, step: 50)
                    Text("\(Int(cursorSpeed))")
                        .frame(width: 50)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Sensitivity")
                    Slider(value: $sensitivity, in: 0.5...2.0, step: 0.1)
                    Text(String(format: "%.1f", sensitivity))
                        .frame(width: 40)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Deadzone")
                    Slider(value: $deadzone, in: 0.05...0.3, step: 0.01)
                    Text(String(format: "%.2f", deadzone))
                        .frame(width: 40)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: cursorSpeed) { newValue in
                appState.cursorSpeed = newValue
            }
            .onChange(of: sensitivity) { newValue in
                appState.sensitivity = newValue
            }
            .onChange(of: deadzone) { newValue in
                appState.deadzone = Float(newValue)
            }
        } header: {
            Text("Cursor")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var buttonMappingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                ButtonMappingRow(label: "Left Trigger", action: appState.buttonMapping.leftTriggerAction.displayName)
                ButtonMappingRow(label: "Right Trigger", action: appState.buttonMapping.rightTriggerAction.displayName)
                ButtonMappingRow(label: "Left Shoulder", action: appState.buttonMapping.leftShoulderAction.displayName)
                ButtonMappingRow(label: "Right Shoulder", action: appState.buttonMapping.rightShoulderAction.displayName)
                ButtonMappingRow(label: "A Button", action: appState.buttonMapping.buttonAAction.displayName)
                ButtonMappingRow(label: "B Button", action: appState.buttonMapping.buttonBAction.displayName)
                ButtonMappingRow(label: "X Button", action: appState.buttonMapping.buttonXAction.displayName)
                ButtonMappingRow(label: "Y Button", action: appState.buttonMapping.buttonYAction.displayName)
                ButtonMappingRow(label: "Left Stick Press", action: appState.buttonMapping.leftStickPressAction.displayName)
                ButtonMappingRow(label: "Right Stick Press", action: appState.buttonMapping.rightStickPressAction.displayName)
            }
        } header: {
            HStack {
                Text("Button Mapping")
                Spacer()
                Button("Edit") {
                    showEditMapping = true
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }

    private var dpadSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                DpadMappingRow(label: "Up", action: appState.buttonMapping.dpadUpAction.displayName)
                DpadMappingRow(label: "Down", action: appState.buttonMapping.dpadDownAction.displayName)
                DpadMappingRow(label: "Left", action: appState.buttonMapping.dpadLeftAction.displayName)
                DpadMappingRow(label: "Right", action: appState.buttonMapping.dpadRightAction.displayName)
            }
        } header: {
            Text("D-Pad")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var footerView: some View {
        HStack {
            Text("v1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
        }
        .padding()
    }
}

struct ButtonMappingRow: View {
    let label: String
    let action: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            Spacer()
            Text(action)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct DpadMappingRow: View {
    let label: String
    let action: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            Spacer()
            Image(systemName: "arrow.\(label.lowercased())")
                .foregroundColor(.secondary)
            Text(action)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

extension ControllerAction {
    var displayName: String {
        switch self {
        case .none: return "None"
        case .leftClick: return "Left Click"
        case .rightClick: return "Right Click"
        case .middleClick: return "Middle Click"
        case .doubleClick: return "Double Click"
        case .leftDrag: return "Left Drag"
        case .rightDrag: return "Right Drag"
        case .scrollUp: return "Scroll Up"
        case .scrollDown: return "Scroll Down"
        case .scrollLeft: return "Scroll Left"
        case .scrollRight: return "Scroll Right"
        case .prevTab: return "Previous Tab"
        case .nextTab: return "Next Tab"
        case .toggleControl: return "Toggle"
        }
    }
}

struct EditButtonMappingSheet: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var mapping: ButtonMapping

    init(appState: AppState) {
        self.appState = appState
        self._mapping = State(initialValue: appState.buttonMapping)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit Button Mapping")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.borderless)
                Button("Save") {
                    appState.buttonMapping = mapping
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            Form {
                Section {
                    Picker("Left Trigger", selection: $mapping.leftTriggerAction) {
                        ForEach(ControllerAction.clickActions, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    Picker("Right Trigger", selection: $mapping.rightTriggerAction) {
                        ForEach(ControllerAction.clickActions, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                } header: {
                    Text("Triggers")
                }

                Section {
                    Picker("Left Shoulder", selection: $mapping.leftShoulderAction) {
                        ForEach(ControllerAction.clickActions, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    Picker("Right Shoulder", selection: $mapping.rightShoulderAction) {
                        ForEach(ControllerAction.clickActions, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                } header: {
                    Text("Shoulders")
                }

                Section {
                    Picker("A Button", selection: $mapping.buttonAAction) {
                        ForEach(ControllerAction.clickActions, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    Picker("B Button", selection: $mapping.buttonBAction) {
                        ForEach(ControllerAction.clickActions, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    Picker("X Button", selection: $mapping.buttonXAction) {
                        ForEach(ControllerAction.clickActions, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    Picker("Y Button", selection: $mapping.buttonYAction) {
                        ForEach(ControllerAction.clickActions, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                } header: {
                    Text("Face Buttons")
                }

                Section {
                    Picker("Left Stick Press", selection: $mapping.leftStickPressAction) {
                        ForEach(ControllerAction.allCases, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    Picker("Right Stick Press", selection: $mapping.rightStickPressAction) {
                        ForEach(ControllerAction.allCases, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                } header: {
                    Text("Stick Press")
                }

                Section {
                    Picker("D-Pad Up", selection: $mapping.dpadUpAction) {
                        ForEach(ControllerAction.allCases, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    Picker("D-Pad Down", selection: $mapping.dpadDownAction) {
                        ForEach(ControllerAction.allCases, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    Picker("D-Pad Left", selection: $mapping.dpadLeftAction) {
                        ForEach(ControllerAction.allCases, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    Picker("D-Pad Right", selection: $mapping.dpadRightAction) {
                        ForEach(ControllerAction.allCases, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                } header: {
                    Text("D-Pad")
                }

                Section {
                    Toggle("Enable Right Stick", isOn: $mapping.rightStickEnabled)
                    if mapping.rightStickEnabled {
                        HStack {
                            Text("Deadzone")
                            Slider(value: Binding(
                                get: { Double(mapping.rightStickDeadzone) },
                                set: { mapping.rightStickDeadzone = Float($0) }
                            ), in: 0.05...0.3, step: 0.01)
                            Text(String(format: "%.2f", mapping.rightStickDeadzone))
                                .frame(width: 40)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Right Stick")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 380, height: 580)
    }
}

extension ControllerAction: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension ControllerAction {
    static var clickActions: [ControllerAction] {
        [.none, .leftClick, .rightClick, .middleClick, .doubleClick, .leftDrag, .rightDrag]
    }
}