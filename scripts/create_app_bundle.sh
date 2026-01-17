#!/bin/bash
#
# Create a macOS application bundle for Shortcut Detective
# This creates a .app that opens Terminal and runs the shortcut detector
#

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Shortcut Detective"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Shortcut Detective.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=================================================="
echo "Creating Shortcut Detective macOS Application Bundle"
echo "=================================================="
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"

# Remove existing app if present
if [ -d "$APP_BUNDLE" ]; then
    echo "Removing existing app bundle..."
    rm -rf "$APP_BUNDLE"
fi

# Create directory structure
echo "Creating directory structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Make sure the shortcut-detective binary exists
if [ ! -f "$PROJECT_DIR/shortcut-detective" ]; then
    echo "Compiling shortcut-detective..."
    swiftc -o "$PROJECT_DIR/shortcut-detective" "$PROJECT_DIR/src/ShortcutDetective.swift"
fi

# Create the launcher script that opens Terminal
echo "Creating launcher script..."
cat > "$MACOS_DIR/shortcut-detective-launcher" << 'LAUNCHER_EOF'
#!/bin/bash
#
# Launcher for Shortcut Detective
# Opens Terminal and runs the shortcut detective
#

APP_PATH="$(cd "$(dirname "$0")/../Resources" && pwd)"
DETECTOR="$APP_PATH/shortcut-detective"

# Create a shell script that Terminal will run
TEMP_SCRIPT=$(mktemp /tmp/shortcut-detective-XXXXXX.sh)
chmod +x "$TEMP_SCRIPT"

cat > "$TEMP_SCRIPT" << EOF
#!/bin/bash
clear
echo "=============================================="
echo "🔍 Shortcut Detective"
echo "=============================================="
echo ""
echo "Press any keyboard shortcuts to detect which app handles them."
echo "Press Ctrl+C to quit."
echo ""
echo "=============================================="
echo ""

# Run the detector
"$DETECTOR"

# Keep terminal open if it crashes
echo ""
echo "Shortcut Detective has stopped."
echo "Press any key to close this window..."
read -n 1
EOF

# Open Terminal with our script
osascript << EOF
tell application "Terminal"
    activate
    do script "exec bash '$TEMP_SCRIPT'; rm -f '$TEMP_SCRIPT'"
end tell
EOF
LAUNCHER_EOF

chmod +x "$MACOS_DIR/shortcut-detective-launcher"

# Copy the compiled binary to Resources
echo "Copying shortcut-detective binary..."
cp "$PROJECT_DIR/shortcut-detective" "$RESOURCES_DIR/shortcut-detective"
chmod +x "$RESOURCES_DIR/shortcut-detective"

# Create Info.plist
echo "Creating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>Shortcut Detective</string>
	<key>CFBundleExecutable</key>
	<string>shortcut-detective-launcher</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.shortcutdetective.app</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Shortcut Detective</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>10.15</string>
	<key>LSUIElement</key>
	<false/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSHumanReadableCopyright</key>
	<string>MIT License</string>
</dict>
</plist>
EOF

# Copy icon if it exists
echo "Setting up application icon..."
if [ -f "$PROJECT_DIR/icons/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/icons/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    echo "✓ Icon copied"
else
    echo "⚠️  Warning: Icon not found at $PROJECT_DIR/icons/AppIcon.icns"
    echo "   Run scripts/create_app_icon.sh to generate one"
fi

# Create PkgInfo file
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo ""
echo "=================================================="
echo "✓ Application bundle created successfully!"
echo "=================================================="
echo ""
echo "Build location: $APP_BUNDLE"
echo ""
echo "To install to /Applications, run:"
echo "   ./scripts/install_app.sh"
echo ""
echo "Or manually:"
echo "   cp -r '$APP_BUNDLE' /Applications/"
echo ""
