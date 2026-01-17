#!/bin/bash
#
# Install Shortcut Detective to /Applications
# This makes it available in Launchpad
#

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Shortcut Detective"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Shortcut Detective.app"
INSTALL_DIR="/Applications"

echo "=================================================="
echo "Installing Shortcut Detective"
echo "=================================================="
echo ""

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found. Building now..."
    bash "$PROJECT_DIR/scripts/create_app_icon.sh"
    bash "$PROJECT_DIR/scripts/create_app_bundle.sh"
fi

# Check again
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: Failed to create app bundle"
    exit 1
fi

# Remove existing installation
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo "Removing existing installation..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

# Copy to /Applications
echo "Installing to $INSTALL_DIR..."
cp -r "$APP_BUNDLE" "$INSTALL_DIR/"

# Verify installation
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo ""
    echo "=================================================="
    echo "✓ Installation successful!"
    echo "=================================================="
    echo ""
    echo "Shortcut Detective is now installed at:"
    echo "   $INSTALL_DIR/$APP_NAME.app"
    echo ""
    echo "You can find it in:"
    echo "   • Launchpad"
    echo "   • Finder > Applications"
    echo "   • Spotlight (Cmd+Space, type 'Shortcut Detective')"
    echo ""
    echo "⚠️  IMPORTANT: Accessibility Permissions"
    echo ""
    echo "When you first launch the app, you may need to grant"
    echo "accessibility permissions to both:"
    echo "   1. Terminal.app"
    echo "   2. shortcut-detective (the binary)"
    echo ""
    echo "Go to: System Settings > Privacy & Security > Accessibility"
    echo ""
else
    echo "❌ Error: Installation failed"
    exit 1
fi
