# Shortcut Detective 🔍

A native macOS application to detect which app is capturing your keyboard shortcuts in real-time, including background apps and keyboard remapping tools.

![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-5.0+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## Features

### 🎯 Real-Time Shortcut Detection
- **Instant monitoring** of all keyboard shortcuts as you press them
- **Background app detection** - finds apps intercepting shortcuts even when not focused
- **Shortcut remapping detection** - identifies when one shortcut is transformed into another
- **Detailed logging** with timestamps and key codes

### 🔍 What It Shows You

For each keyboard shortcut pressed, you'll see:
- The exact shortcut combination (e.g., `⌘⌥ + F`)
- Which app is currently frontmost
- Whether a background app is handling it instead
- If the shortcut was synthesized/remapped by another app
- Common global shortcut apps running in the background
- Raw key codes for debugging

### 💡 Perfect For

- **Finding shortcut conflicts** - discover which app is "stealing" your shortcuts
- **Debugging remapping tools** - see how Alfred, BetterTouchTool, Karabiner, etc. transform shortcuts
- **Configuring apps** - verify your custom shortcuts are being received correctly
- **Troubleshooting** - understand why a shortcut isn't working as expected

## Example Output

```
[15:27:10] 🎯 Shortcut: ⌘⌥ + F
   Frontmost App: iTerm2 (com.googlecode.iterm2)
   ✓ Handler: Frontmost app (no interception detected)
   🔍 Apps with global shortcuts running:
      - Raycast (com.raycast.macos)
      - Contexts (com.contextsformac.Contexts)
      - Spectacle (com.divisiblebyzero.Spectacle)
   KeyCode: 3

[15:27:10] 🔄 REMAPPED SHORTCUT: ⌘ + C
   🚨 This shortcut was SYNTHESIZED by another app!
   Original shortcut: ⌘⌥ + F
   → Transformed into: ⌘ + C
   ⚠️  REMAPPING APP: Alfred (com.runningwithcrayons.Alfred)
   Target: iTerm2 (com.googlecode.iterm2)
   KeyCode: 8
   ⚙️  Event Type: Software-generated (synthesized)
```

This tells you that **Alfred** intercepted `Cmd+Opt+F` and remapped it to `Cmd+C`!

## Requirements

- **macOS**: 10.15 (Catalina) or later
- **Swift**: 5.0+ (comes with Xcode Command Line Tools)
- **Accessibility Permissions**: Required to monitor keyboard events system-wide

## Installation

### Quick Install (Recommended)

```bash
git clone https://github.com/vijaydaultani/shortcut-detective.git
cd shortcut-detective
chmod +x scripts/*.sh
./scripts/install_app.sh
```

The installer will:
1. Generate the app icon
2. Compile the Swift application
3. Create a macOS app bundle
4. Install to `/Applications`

### What Gets Installed

- **Shortcut Detective.app** in `/Applications`
- Available in Launchpad, Spotlight, and Finder

### Manual Installation

```bash
# Compile the app
swiftc -o shortcut-detective src/ShortcutDetective.swift

# Run directly in terminal
./shortcut-detective
```

## Usage

### Launching the App

You can launch Shortcut Detective from:
- **Launchpad** - Click the magnifying glass icon
- **Spotlight** - Press `Cmd+Space`, type "Shortcut Detective"
- **Finder** - Go to Applications folder

When launched, a **Terminal window** opens automatically with the detector running.

### First Run - Grant Permissions

You need to grant **Accessibility Permissions**:

1. Go to: **System Settings** > **Privacy & Security** > **Accessibility**
2. Enable **Terminal** (required to run the app)
3. If prompted, also enable **shortcut-detective**

### Understanding the Output

**Normal Shortcuts** (handled by frontmost app):
```
🎯 Shortcut: ⌘ + C
   Frontmost App: Safari (com.apple.Safari)
   ✓ Handler: Frontmost app (no interception detected)
```

**Background App Interception**:
```
🎯 Shortcut: ⌘ + Space
   Frontmost App: Safari (com.apple.Safari)
   ⚠️  ACTUAL HANDLER: Raycast (com.raycast.macos) - BACKGROUND APP!
```

**Remapped Shortcuts**:
```
🔄 REMAPPED SHORTCUT: ⌘ + C
   🚨 This shortcut was SYNTHESIZED by another app!
   Original shortcut: ⌘⌥ + F
   → Transformed into: ⌘ + C
   ⚠️  REMAPPING APP: Alfred (com.runningwithcrayons.Alfred)
```

### Stopping the App

Press `Ctrl+C` in the Terminal window to stop monitoring.

## Scripts

```bash
# Install the app to /Applications
./scripts/install_app.sh

# Uninstall completely
./scripts/uninstall.sh

# Regenerate the app icon
./scripts/create_app_icon.sh

# Rebuild the app bundle
./scripts/create_app_bundle.sh
```

## Detected Apps

Shortcut Detective automatically recognizes these common global shortcut tools:

- **Alfred** - `com.runningwithcrayons.Alfred`
- **Raycast** - `com.raycast.macos`
- **BetterTouchTool** - `com.BetterTouchTool`
- **Rectangle/Spectacle** - `com.knollsoft.Rectangle`, `com.divisiblebyzero.Spectacle`
- **Contexts** - `com.contextsformac.Contexts`
- **Moom** - `com.manytricks.Moom`
- **Karabiner** - `com.bahoom.Keyboard`

## Project Structure

```
shortcut_detective/
├── src/
│   └── ShortcutDetective.swift    # Main application code
├── scripts/
│   ├── create_app_bundle.sh       # Creates the .app bundle
│   ├── create_app_icon.sh         # Generates the app icon
│   ├── install_app.sh             # Installs to /Applications
│   └── uninstall.sh               # Removes everything
├── icons/
│   ├── AppIcon.icns               # macOS app icon
│   └── AppIcon.png                # PNG version
├── README.md                       # This file
├── QUICKSTART.md                   # Quick setup guide
└── LICENSE                         # MIT License
```

## How It Works

### Technical Details

1. **Event Taps**: Uses CGEvent API to monitor keyboard events at the system level
2. **Process Detection**: Identifies source and target processes for each event
3. **Hardware vs Software Events**: Distinguishes between real keypresses and synthesized events
4. **Timing Analysis**: Detects rapid successive events indicating remapping
5. **Bundle ID Matching**: Recognizes known global shortcut applications

### Event Flow

```
User presses Cmd+Opt+F
    ↓
Shortcut Detective captures event
    ↓
Checks if event is from hardware (keyboard) or software (synthesized)
    ↓
Identifies frontmost application
    ↓
Checks if target PID differs from frontmost app
    ↓
Detects if event happens within 100ms of previous event
    ↓
Displays detailed analysis
```

## Troubleshooting

### App Not Starting

**Check if Terminal has Accessibility permissions:**
1. Go to System Settings > Privacy & Security > Accessibility
2. Ensure Terminal is enabled

### "Failed to create event tap" Error

This means accessibility permissions are missing:
1. Go to System Settings > Privacy & Security > Accessibility
2. Add and enable both **Terminal** and **shortcut-detective**
3. Restart the app

### No Output When Pressing Shortcuts

1. **Verify accessibility permissions** are granted
2. **Only shortcuts with modifiers** are shown (plain keys are filtered out)
3. Make sure the Terminal window has focus when reading output

## Security & Privacy

### Permissions Required

- **Accessibility Access**: Required to monitor keyboard events system-wide
- This is the same permission required by apps like Alfred, Rectangle, BetterTouchTool, etc.

### What Data Is Collected

- **None**. All keyboard events are processed in real-time and displayed only
- No data is stored, transmitted, or shared
- No network connections are made
- Runs entirely locally on your Mac

## Uninstallation

```bash
./scripts/uninstall.sh
```

This will:
- Remove the app from /Applications
- Clean up build artifacts
- Remove log files

## Development

### Building from Source

```bash
# Generate icon
./scripts/create_app_icon.sh

# Create app bundle
./scripts/create_app_bundle.sh

# Install to Applications
./scripts/install_app.sh
```

### Adding More Detected Apps

Edit `src/ShortcutDetective.swift` and add to the `globalShortcutApps` array:

```swift
let globalShortcutApps = [
    "com.raycast.macos",
    "com.alfred",
    "com.your.app.bundle.id"  // Add here
]
```

Then reinstall:
```bash
./scripts/uninstall.sh
./scripts/install_app.sh
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

### Technologies

- **Swift** - Native macOS development
- **Core Graphics (CGEvent)** - System-level keyboard monitoring
- **Cocoa/AppKit** - macOS application framework
- **Pillow** - Icon generation

## Changelog

### Version 1.0.0

- Initial release
- Real-time keyboard shortcut monitoring
- Background app detection
- Shortcut remapping detection
- Launchpad-ready macOS app bundle
- Custom app icon

---

**Made with ❤️ for macOS power users**

*Stop wondering which app is stealing your shortcuts!*
