#!/bin/bash

set -e

echo "🔍 Shortcut Detective - Uninstall Script"
echo "========================================"
echo

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BUNDLE_ID="com.shortcutdetective.menubar"
LAUNCHAGENT_PLIST="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPILED_APP="$PROJECT_DIR/shortcut-detective"
APP_INSTALL="/Applications/Shortcut Detective.app"

# Stop and unload LaunchAgent
echo "🛑 Stopping Shortcut Detective..."
if launchctl list | grep -q "$BUNDLE_ID"; then
    launchctl unload "$LAUNCHAGENT_PLIST" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} LaunchAgent stopped"
else
    echo "   LaunchAgent not running"
fi

# Remove LaunchAgent plist
if [ -f "$LAUNCHAGENT_PLIST" ]; then
    rm "$LAUNCHAGENT_PLIST"
    echo -e "${GREEN}✓${NC} LaunchAgent configuration removed"
fi

# Kill any running processes
pkill -f "shortcut-detective" 2>/dev/null || true
echo -e "${GREEN}✓${NC} All processes terminated"

# Remove from /Applications
if [ -d "$APP_INSTALL" ]; then
    rm -rf "$APP_INSTALL"
    echo -e "${GREEN}✓${NC} Removed from /Applications"
fi

# Remove build directory
if [ -d "$PROJECT_DIR/build" ]; then
    rm -rf "$PROJECT_DIR/build"
    echo -e "${GREEN}✓${NC} Build directory removed"
fi

# Remove compiled binary
if [ -f "$COMPILED_APP" ]; then
    rm "$COMPILED_APP"
    echo -e "${GREEN}✓${NC} Compiled binary removed"
fi

# Remove log files
rm -f /tmp/shortcut-detective.out /tmp/shortcut-detective.err
rm -f /tmp/shortcut-detective-*.sh
echo -e "${GREEN}✓${NC} Log files removed"

echo
echo "✅ Uninstallation complete!"
echo
echo "The source code is still available at:"
echo "   $PROJECT_DIR"
echo
echo "To reinstall, run:"
echo "   $SCRIPT_DIR/install_app.sh"
echo
