#!/bin/bash

# OSGA Simulator Launcher for Linux
# Usage: ./run_linux.sh [app_name]

set -e

# Colors for output (check if terminal supports colors)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

echo -e "${GREEN}🎮 OSGA Simulator${NC}"
echo "-------------------"

# Function to find Love2D
find_love() {
    # Check common command names
    for cmd in love love2d love11; do
        if command -v $cmd &> /dev/null; then
            echo $cmd
            return 0
        fi
    done
    
    # Check flatpak
    if command -v flatpak &> /dev/null; then
        if flatpak list | grep -q "org.love2d.love"; then
            echo "flatpak run org.love2d.love"
            return 0
        fi
    fi
    
    # Check snap
    if command -v snap &> /dev/null; then
        if snap list | grep -q "love"; then
            echo "snap run love"
            return 0
        fi
    fi
    
    return 1
}

# Find Love2D
LOVE_CMD=$(find_love)

if [ -z "$LOVE_CMD" ]; then
    echo -e "${RED}❌ Love2D is not installed${NC}"
    echo ""
    echo "Please install Love2D using one of these methods:"
    echo ""
    echo -e "${BLUE}Ubuntu/Debian:${NC}"
    echo "  sudo apt-get update && sudo apt-get install love2d"
    echo ""
    echo -e "${BLUE}Arch Linux:${NC}"
    echo "  sudo pacman -S love"
    echo ""
    echo -e "${BLUE}Fedora:${NC}"
    echo "  sudo dnf install love"
    echo ""
    echo -e "${BLUE}Flatpak (Universal):${NC}"
    echo "  flatpak install flathub org.love2d.love"
    echo ""
    echo -e "${BLUE}Or download from:${NC} https://love2d.org/"
    exit 1
fi

# Get Love2D version
LOVE_VERSION=$($LOVE_CMD --version 2>&1 | head -n 1)
echo -e "✓ Found: ${YELLOW}$LOVE_VERSION${NC}"
echo -e "  Using command: ${BLUE}$LOVE_CMD${NC}"

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
                echo "  - $(basename "$app")"
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
    echo ""
    echo "Available apps:"
    for app in apps/*/; do
        if [ -f "$app/main.lua" ]; then
            echo "  - $(basename "$app")"
        fi
    done
    exit 1
fi