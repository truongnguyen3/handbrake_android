#!/bin/bash

# HandBrake Android Minimal Build Script
# This script builds HandBrake with minimal dependencies for initial testing

set -e

# Auto-detect NDK if not provided
if [ -z "$ANDROID_NDK_ROOT" ]; then
    if [ -d "$HOME/Library/Android/sdk/ndk" ]; then
        # macOS typical location
        NDK_BASE="$HOME/Library/Android/sdk/ndk"
    elif [ -d "$HOME/Android/Sdk/ndk" ]; then
        # Linux/Windows typical location
        NDK_BASE="$HOME/Android/Sdk/ndk"
    else
        echo "Error: Could not find NDK directory"
        echo "Please set ANDROID_NDK_ROOT environment variable"
        exit 1
    fi
    
    # Find the latest recommended NDK version (25.x or 26.x)
    RECOMMENDED_NDK=$(ls "$NDK_BASE" | grep -E "^2[56]\." | sort -V | tail -n 1)
    if [ -n "$RECOMMENDED_NDK" ]; then
        export ANDROID_NDK_ROOT="$NDK_BASE/$RECOMMENDED_NDK"
        echo "Auto-detected NDK: $ANDROID_NDK_ROOT"
    else
        # Fall back to any available version
        LATEST_NDK=$(ls "$NDK_BASE" | sort -V | tail -n 1)
        if [ -n "$LATEST_NDK" ]; then
            export ANDROID_NDK_ROOT="$NDK_BASE/$LATEST_NDK"
            echo "Using latest available NDK: $ANDROID_NDK_ROOT"
        else
            echo "Error: No NDK versions found in $NDK_BASE"
            exit 1
        fi
    fi
else
    echo "Using provided NDK: $ANDROID_NDK_ROOT"
fi

# Configuration
export ANDROID_API_LEVEL=${ANDROID_API_LEVEL:-21}
export HANDBRAKE_ROOT=${HANDBRAKE_ROOT:-".."}

echo "Building HandBrake minimal AAR for Android..."
echo "NDK: $ANDROID_NDK_ROOT"
echo "API Level: $ANDROID_API_LEVEL"
echo "HandBrake Root: $HANDBRAKE_ROOT"

# Check if NDK exists
if [ ! -d "$ANDROID_NDK_ROOT" ]; then
    echo "Error: Android NDK not found at $ANDROID_NDK_ROOT"
    echo "Available NDK versions:"
    ls "$HOME/Library/Android/sdk/ndk/" 2>/dev/null || ls "$HOME/Android/Sdk/ndk/" 2>/dev/null || echo "No NDK found"
    echo "Please set ANDROID_NDK_ROOT environment variable to one of the above"
    exit 1
fi

# Create directories
mkdir -p src/main/cpp/prebuilt
mkdir -p src/main/cpp/handbrake-source

# Copy essential HandBrake source files
echo "Copying HandBrake source files..."
cp "$HANDBRAKE_ROOT/libhb/"*.c src/main/cpp/handbrake-source/ 2>/dev/null || true
cp "$HANDBRAKE_ROOT/libhb/"*.h src/main/cpp/handbrake-source/ 2>/dev/null || true
cp -r "$HANDBRAKE_ROOT/libhb/handbrake" src/main/cpp/handbrake-source/ 2>/dev/null || true
cp -r "$HANDBRAKE_ROOT/libhb/platform" src/main/cpp/handbrake-source/ 2>/dev/null || true

# Check if files were copied
if [ "$(ls -A src/main/cpp/handbrake-source/)" ]; then
    echo "✓ HandBrake source files copied successfully"
    echo "Files copied: $(ls src/main/cpp/handbrake-source/ | wc -l | tr -d ' ') files"
else
    echo "✗ No HandBrake source files were copied"
    echo "Please check the HANDBRAKE_ROOT path: $HANDBRAKE_ROOT"
    exit 1
fi

# Create stub libraries for missing dependencies
echo "Creating stub libraries for missing dependencies..."
for abi in "arm64-v8a" "armeabi-v7a" "x86" "x86_64"; do
    mkdir -p "src/main/cpp/prebuilt/$abi/lib"
    mkdir -p "src/main/cpp/prebuilt/$abi/include"
    
    # Create minimal stub libraries
    echo "Creating stub libraries for $abi..."
    
    # Create empty static libraries as placeholders
    for lib in libx264 libx265 libavcodec libavformat libavutil libswscale; do
        touch "src/main/cpp/prebuilt/$abi/lib/${lib}.a"
    done
done

echo ""
echo "Minimal build preparation completed!"
echo ""
echo "Next steps:"
echo "1. The HandBrake source has been copied to src/main/cpp/handbrake-source/"
echo "2. Stub libraries have been created for dependencies"
echo "3. You can now build the AAR with: ./gradlew assembleRelease"
echo ""
echo "Note: This is a minimal build for testing the build system."
echo "For full functionality, you'll need to build the actual dependencies."