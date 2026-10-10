# ControllerMouse

A macOS menu bar app that lets you use a game controller to control your mouse cursor. Perfect for accessibility use cases, couch computing, or any situation where you want granular cursor control via a gamepad.

## Features

- **Left/Right Stick Mouse Control** — Use your controller's analog sticks to move the cursor with adjustable speed and sensitivity
- **Click & Drag** — Full support for left-click, right-click, and drag operations via controller buttons
- **Configurable Deadzone** — Calibrate stick deadzone to suit your controller
- **Menu Bar App** — Runs quietly in your menu bar, always accessible
- **Persistent Settings** — Your preferences are saved automatically

## Default controls and customization

These are the checked-in defaults in `Sources/Configuration/ButtonMapping.swift`; saved preferences can override them in the settings popover.

| Controller input | Default action |
| --- | --- |
| Left / right stick | Move cursor (each stick can be configured independently) |
| A / Cross | Left click |
| B / Circle | Right click |
| X / Square | Middle click |
| Y / Triangle | Double click |
| LB / L1 | Right click |
| RB / R1 | Right drag |
| LT / L2 | Left click |
| RT / R2 | Left drag |
| Left stick press | Toggle controller cursor control |
| Right stick press | Double click |
| D-pad up / down | Scroll vertically |
| D-pad left / right | Previous / next tab (Control-Shift-Tab / Control-Tab) |

D-pad inputs honor the configured action, including `None`, mouse clicks/drags,
scrolling and tab switching. Scroll direction follows the mapping, so any D-pad
input can scroll horizontally or vertically. Tab switching sends balanced
Control-Tab or Control-Shift-Tab keystrokes once per press; support depends on the
focused application. Releasing a button or D-pad drag releases the mouse button,
even if its mapping changed while held.

Stick speed, deadzones, button mappings and preferences are exposed in the settings UI. Actual controller/device behavior has not been revalidated as part of this documentation update.

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

## Verification

On macOS with the Xcode command line tools available:

```bash
bash scripts/test-mappings.sh
xcodebuild -project ControllerMouse.xcodeproj -scheme ControllerMouse \
  -configuration Debug -derivedDataPath /tmp/ControllerMouse-build \
  CODE_SIGNING_ALLOWED=NO build
```

The mapping tests capture generated events rather than posting them to the desktop.
They cover tab shortcut press/release balance, held-button suppression, disabled
D-pad input, remapped scroll axes and drag release after a mapping change. CI runs
these checks and builds the app. Physical gamepad polling, Accessibility permissions
and focused-app shortcut behavior still require device testing.

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
