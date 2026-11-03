#!/bin/bash

# MenuTerm build script

set -e

# Project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Defaults
CONFIG="${CONFIG:-Debug}"
CLEAN="${CLEAN:-false}"
ARCHIVE="${ARCHIVE:-false}"

# Build configuration
PROJECT="MenuTerm.xcodeproj"
SCHEME="MenuTerm"
BUILD_DIR="build"
DERIVED_DATA="$BUILD_DIR/DerivedData"

# Colored output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -c, --config CONFIG    Build configuration: Debug or Release (default: Debug)"
    echo "  -C, --clean            Clean before building"
    echo "  -a, --archive          Create an archive"
    echo "  -h, --help             Show help"
    echo ""
    echo "Environment variables:"
    echo "  CONFIG=Release         Same as -c Release"
    echo "  CLEAN=true             Same as -C"
    echo "  ARCHIVE=true           Same as -a"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build Debug"
    echo "  $0 -c Release         # Build Release"
    echo "  $0 -c Release -C      # Clean and build Release"
    echo "  CONFIG=Release $0      # Build Release (Environment variables)"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG="$2"
            shift 2
            ;;
        -C|--clean)
            CLEAN=true
            shift
            ;;
        -a|--archive)
            ARCHIVE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Validate configuration
if [[ "$CONFIG" != "Debug" && "$CONFIG" != "Release" ]]; then
    echo -e "${RED}Error: CONFIG must be Debug or Release${NC}"
    exit 1
fi

# Print build info
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}MenuTerm build script${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo "Config:   $CONFIG"
echo "Clean:    $CLEAN"
echo "Archive:  $ARCHIVE"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# Build
if [[ "$ARCHIVE" == "true" ]]; then
    # Archive build
    ARCHIVE_PATH="$BUILD_DIR/MenuTerm.xcarchive"

    echo "Create an archive..."
    xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIG" \
        -derivedDataPath "$DERIVED_DATA" \
        -archivePath "$ARCHIVE_PATH" \
        CLEAN=$CLEAN

    # Copy .app
    APP_PATH="$BUILD_DIR/MenuTerm.app"
    rm -rf "$APP_PATH"
    cp -R "$ARCHIVE_PATH/Products/Applications/MenuTerm.app" "$APP_PATH"

    echo ""
    echo -e "${GREEN}✓ Build succeeded!${NC}"
    echo "App: $APP_PATH"
    echo "Archive: $ARCHIVE_PATH"

else
    # Regular build
    echo "Building $CONFIG..."
    xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIG" \
        -derivedDataPath "$DERIVED_DATA" \
        CLEAN=$CLEAN

    # Copy .app
    APP_PATH="$BUILD_DIR/$CONFIG/MenuTerm.app"
    rm -rf "$APP_PATH"
    mkdir -p "$(dirname "$APP_PATH")"
    cp -R "$DERIVED_DATA/Build/Products/$CONFIG/MenuTerm.app" "$APP_PATH"

    echo ""
    echo -e "${GREEN}✓ Build succeeded!${NC}"
    echo "App: $APP_PATH"
fi
