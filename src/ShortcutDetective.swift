#!/usr/bin/env swift

import Cocoa
import ApplicationServices
import Carbon

class ShortcutDetective {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastEventTime: TimeInterval = 0
    private var lastShortcut: String = ""
    private var lastEventSource: Int64 = 0

    func start() {
        print("🔍 Shortcut Detective Started!")
        print("Detecting which app ACTUALLY handles your shortcuts (including background apps)")
        print("Press Ctrl+C to quit.\n")

        // Check for accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("⚠️  Accessibility permissions required!")
            print("Please go to: System Settings > Privacy & Security > Accessibility")
            print("and grant permission to Terminal (or this app).\n")
            print("The app will still run but may have limited detection capabilities.\n")
        }

        // Create event tap with default options (not listenOnly) to track if events are consumed
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,  // Changed from .listenOnly to track consumption
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("❌ Failed to create event tap. Make sure you have Accessibility permissions.")
            return
        }

        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("✅ Event monitoring active. Watching for shortcuts...\n")

        // Run the app
        CFRunLoopRun()
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        CFRunLoopStop(CFRunLoopGetCurrent())
    }

    fileprivate func handleEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let type = event.type

        // Get the frontmost application
        let workspace = NSWorkspace.shared
        guard let activeApp = workspace.frontmostApplication else {
            return Unmanaged.passRetained(event)
        }

        let frontAppName = activeApp.localizedName ?? "Unknown"
        let frontBundleId = activeApp.bundleIdentifier ?? "Unknown"

        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags

            // Build modifier string
            var modifiers: [String] = []
            if flags.contains(.maskCommand) { modifiers.append("⌘") }
            if flags.contains(.maskShift) { modifiers.append("⇧") }
            if flags.contains(.maskAlternate) { modifiers.append("⌥") }
            if flags.contains(.maskControl) { modifiers.append("⌃") }
            if flags.contains(.maskSecondaryFn) { modifiers.append("fn") }

            // Get the key character
            let keyChar = keyCodeToString(keyCode)

            let modifierStr = modifiers.isEmpty ? "" : modifiers.joined() + " + "
            let shortcut = "\(modifierStr)\(keyChar)"

            // Only print if there are modifiers (to avoid cluttering with regular typing)
            if !modifiers.isEmpty {
                let currentTime = Date().timeIntervalSince1970
                let timestamp = Date().formatted(date: .omitted, time: .standard)
                let timeSinceLastEvent = currentTime - lastEventTime

                // Try to get the target process that will receive the event
                let targetPID = event.getIntegerValueField(.eventTargetUnixProcessID)
                let sourcePID = event.getIntegerValueField(.eventSourceUnixProcessID)
                let eventSource = event.getIntegerValueField(.eventSourceUserData)

                // Check if this is a hardware event (from keyboard) or software event (synthesized)
                let eventSourceID = CGEventSource(event: event)
                let isHardwareEvent = (sourcePID == 0)

                var actualHandler = frontAppName
                var actualBundleId = frontBundleId
                var isBackgroundApp = false

                // If target PID is different from frontmost app, find out which app it is
                if targetPID != 0 && targetPID != activeApp.processIdentifier {
                    if let targetApp = NSRunningApplication(processIdentifier: pid_t(targetPID)) {
                        actualHandler = targetApp.localizedName ?? "Unknown"
                        actualBundleId = targetApp.bundleIdentifier ?? "Unknown"
                        isBackgroundApp = true
                    }
                }

                // Check if there are any running apps with global hotkeys registered
                let runningApps = workspace.runningApplications
                var suspectedHandlers: [String] = []

                // Look for background apps that might be intercepting shortcuts
                for app in runningApps {
                    // Skip the frontmost app and system processes
                    if app.processIdentifier == activeApp.processIdentifier { continue }
                    if app.bundleIdentifier?.hasPrefix("com.apple.") == true { continue }

                    // Check if app has accessibility features that might indicate global hotkey handling
                    if let bundleId = app.bundleIdentifier {
                        // Common apps known to use global shortcuts
                        let globalShortcutApps = [
                            "com.raycast.macos", "com.alfred", "com.contexts",
                            "com.divisiblebyzero.Spectacle", "com.knollsoft.Rectangle",
                            "com.bahoom.Keyboard", "com.BetterTouchTool",
                            "com.manytricks.Moom", "com.mizage.divvy"
                        ]

                        if globalShortcutApps.contains(where: { bundleId.contains($0) }) {
                            if let appName = app.localizedName {
                                suspectedHandlers.append("\(appName) (\(bundleId))")
                            }
                        }
                    }
                }

                // Detect if this is a synthesized/remapped shortcut (happening immediately after another)
                let isSynthesized = !isHardwareEvent || (timeSinceLastEvent < 0.1 && !lastShortcut.isEmpty)

                if isSynthesized {
                    print("[\(timestamp)] 🔄 REMAPPED SHORTCUT: \(shortcut)")
                    print("   🚨 This shortcut was SYNTHESIZED by another app!")
                    print("   Original shortcut: \(lastShortcut)")
                    print("   → Transformed into: \(shortcut)")
                    if sourcePID != 0 {
                        if let sourceApp = NSRunningApplication(processIdentifier: pid_t(sourcePID)) {
                            let sourceAppName = sourceApp.localizedName ?? "Unknown"
                            let sourceBundleId = sourceApp.bundleIdentifier ?? "Unknown"
                            print("   ⚠️  REMAPPING APP: \(sourceAppName) (\(sourceBundleId))")
                        }
                    } else if !suspectedHandlers.isEmpty {
                        print("   🔍 Likely remapped by one of:")
                        for handler in suspectedHandlers {
                            print("      - \(handler)")
                        }
                    }
                    print("   Target: \(frontAppName) (\(frontBundleId))")
                } else {
                    print("[\(timestamp)] 🎯 Shortcut: \(shortcut)")
                    print("   Frontmost App: \(frontAppName) (\(frontBundleId))")

                    if isBackgroundApp {
                        print("   ⚠️  ACTUAL HANDLER: \(actualHandler) (\(actualBundleId)) - BACKGROUND APP!")
                    } else {
                        print("   ✓ Handler: Frontmost app (no interception detected)")
                    }

                    if !suspectedHandlers.isEmpty {
                        print("   🔍 Apps with global shortcuts running:")
                        for handler in suspectedHandlers {
                            print("      - \(handler)")
                        }
                    }
                }

                print("   KeyCode: \(keyCode)")
                if !isHardwareEvent {
                    print("   ⚙️  Event Type: Software-generated (synthesized)")
                }
                print()

                // Track this event for next comparison
                lastEventTime = currentTime
                lastShortcut = shortcut
                lastEventSource = eventSource
            }
        } else if type == .flagsChanged {
            // Don't print modifier-only events to reduce noise
            // Only track them if needed for debugging
        }

        return Unmanaged.passRetained(event)
    }

    private func keyCodeToString(_ keyCode: Int64) -> String {
        // Map common key codes to characters
        let keyMap: [Int64: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 50: "`",
            36: "Return", 48: "Tab", 49: "Space", 51: "Delete",
            53: "Escape", 54: "Right Command", 55: "Command",
            56: "Shift", 57: "Caps Lock", 58: "Option", 59: "Control",
            60: "Right Shift", 61: "Right Option", 62: "Right Control",
            63: "Function", 64: "F17", 65: ".", 67: "*", 69: "+",
            71: "Clear", 75: "/", 76: "Enter", 78: "-", 79: "F18",
            80: "F19", 81: "=", 82: "0", 83: "1", 84: "2", 85: "3",
            86: "4", 87: "5", 88: "6", 89: "7", 91: "8", 92: "9",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
            101: "F9", 103: "F11", 105: "F13", 106: "F16", 107: "F14",
            109: "F10", 111: "F12", 113: "F15", 114: "Help",
            115: "Home", 116: "Page Up", 117: "Delete Forward",
            118: "F4", 119: "End", 120: "F2", 121: "Page Down",
            122: "F1", 123: "Left Arrow", 124: "Right Arrow",
            125: "Down Arrow", 126: "Up Arrow"
        ]

        return keyMap[keyCode] ?? "Key(\(keyCode))"
    }
}

// C callback function for event tap
func eventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if let userInfo = userInfo {
        let detective = Unmanaged<ShortcutDetective>.fromOpaque(userInfo).takeUnretainedValue()
        return detective.handleEvent(event)
    }
    return Unmanaged.passRetained(event)
}

// Main execution
let detective = ShortcutDetective()

// Handle Ctrl+C gracefully
signal(SIGINT) { _ in
    print("\n\n👋 Stopping Shortcut Detective...")
    exit(0)
}

detective.start()
