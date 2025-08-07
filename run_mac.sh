#!/bin/bash

# OSGA Simulator Launcher for macOS
# Usage: ./run_mac.sh [app_name]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🎮 OSGA Simulator${NC}"
echo "-------------------"

# Find Love2D installation
LOVE_CMD=""

# Check common locations
if [ -f "/Applications/love.app/Contents/MacOS/love" ]; then
    LOVE_CMD="/Applications/love.app/Contents/MacOS/love"
elif command -v love &> /dev/null 2>&1; then
    LOVE_CMD="love"
elif [ -f "/usr/local/bin/love" ]; then
    LOVE_CMD="/usr/local/bin/love"
elif [ -f "$HOME/Applications/love.app/Contents/MacOS/love" ]; then
    LOVE_CMD="$HOME/Applications/love.app/Contents/MacOS/love"
else
    echo -e "${RED}❌ Love2D is not installed${NC}"
    echo ""
    echo "Please install Love2D using one of these methods:"
    echo "  1. Download from: https://love2d.org/"
    echo "  2. Homebrew: brew install love"
    echo "  3. Move love.app to /Applications folder"
    exit 1
fi

echo -e "✓ Found Love2D at: ${YELLOW}$LOVE_CMD${NC}"

# Get Love2D version
LOVE_VERSION=$($LOVE_CMD --version 2>&1 | head -n 1)
echo -e "✓ Version: ${YELLOW}$LOVE_VERSION${NC}"

# Check if we're in the right directory
if [ ! -d "osga-sim" ]; then
    echo -e "${RED}❌ Error: osga-sim directory not found${NC}"
    echo "Please run this script from the OSGA root directory"
    exit 1
fi

# Launch simulator with optional app parameter
if [ $# -eq 0 ]; then
    echo -e "🚀 Launching OSGA Simulator..."
    $LOVE_CMD osga-sim
elif [ $# -eq 1 ]; then
    APP_PATH="apps/$1"
    if [ -d "$APP_PATH" ]; then
        echo -e "🚀 Launching OSGA with app: ${GREEN}$1${NC}"
        $LOVE_CMD osga-sim "$APP_PATH"
    else
        echo -e "${RED}❌ App not found: $1${NC}"
        echo ""
        echo "Available apps:"
        for app in apps/*/; do
            if [ -f "$app/main.lua" ]; then
                basename "$app"
            fi
        done
        exit 1
    fi
else
    echo "Usage: $0 [app_name]"
    echo ""
    echo "Examples:"
    echo "  $0              # Launch with default app (kumo)"
    echo "  $0 mariawa      # Launch mariawa app"
    echo "  $0 hardtest     # Launch hardware test"
    exit 1
fi