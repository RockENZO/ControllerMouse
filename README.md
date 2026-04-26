# ControllerMouse

A macOS menu bar app that lets you use a game controller to control your mouse cursor. Perfect for accessibility use cases, couch computing, or any situation where you want granular cursor control via a gamepad.

## Features

- **Left/Right Stick Mouse Control** — Use your controller's analog sticks to move the cursor with adjustable speed and sensitivity
- **Click & Drag** — Full support for left-click, right-click, and drag operations via controller buttons
- **Configurable Deadzone** — Calibrate stick deadzone to suit your controller
- **Menu Bar App** — Runs quietly in your menu bar, always accessible
- **Persistent Settings** — Your preferences are saved automatically

## Controls

| Controller Button | Action |
|-------------------|--------|
| Left Stick | Move cursor |
| Right Stick | Move cursor |
| A / X | Left click |
| B / Circle | Right click |
| X / Square | Left click + drag (hold) |
| Y / Triangle | Right click + drag (hold) |
| LB / L1 | Scroll left |
| RB / R1 | Scroll right |
| LT / L2 | Scroll down |
| RT / R2 | Scroll up |

## Requirements

- macOS 13.0 (Ventura) or later
- A supported game controller (Xbox, PlayStation, or similar HID controller)
- **Accessibility permission** — Required for cursor simulation (the app will prompt you on first launch)

## Building from Source

### Prerequisites

- [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed
- Xcode 15.0 or later

### Build Steps

1. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

2. Open the project in Xcode:
   ```bash
   open ControllerMouse.xcodeproj
   ```

3. Select your signing team in **Project Settings → Signing & Capabilities**

4. Build and run with **Cmd+R**

> **Note:** On first launch, grant Accessibility permission in **System Settings → Privacy & Security → Accessibility**.

## Project Structure

```
Sources/
├── App/
│   ├── main.swift              # Application entry point
│   ├── AppState.swift          # Shared app state (ObservableObject)
│   └── ControllerMouseApp.swift # AppDelegate
├── Configuration/
│   └── ButtonMapping.swift     # Controller button mapping configuration
├── Controllers/
│   ├── GameControllerManager.swift      # HID gamepad discovery & monitoring
│   └── ControllerInputHandler.swift     # Maps controller input → cursor actions
├── Mouse/
│   ├── MouseController.swift    # Cursor movement simulation
│   ├── ClickDragHandler.swift   # Click & drag logic
│   └── KeyboardSimulator.swift  # Keyboard shortcut simulation
├── Permissions/
│   └── AccessibilityPermissionHandler.swift  # Accessibility permission helpers
└── UI/
    ├── MenuBarController.swift  # Menu bar icon & popover toggle
    └── SettingsView.swift       # SwiftUI settings popover
```

## License

MIT