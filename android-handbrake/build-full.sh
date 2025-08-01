#!/bin/bash

# HandBrake Android Full Build Script
# This script builds HandBrake with full functionality after dependencies are built

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

echo "Building HandBrake full functionality AAR for Android..."
echo "NDK: $ANDROID_NDK_ROOT"
echo "API Level: $ANDROID_API_LEVEL"
echo "HandBrake Root: $HANDBRAKE_ROOT"
echo ""

# Check if dependencies are built
PREBUILT_DIR="$(pwd)/prebuilt/android"
if [ ! -d "$PREBUILT_DIR" ]; then
    echo "Error: Prebuilt dependencies not found at $PREBUILT_DIR"
    echo "Please run build-dependencies.sh first to build HandBrake dependencies"
    exit 1
fi

# Check for essential libraries
ESSENTIAL_LIBS=(
    "lib/libx264.a"
    "lib/libx265.a" 
    "lib/libavcodec.a"
    "lib/libavformat.a"
    "lib/libavutil.a"
    "lib/libavfilter.a"
    "lib/libswscale.a"
    "lib/libswresample.a"
)

echo "Checking for essential libraries..."
MISSING_LIBS=()
for lib in "${ESSENTIAL_LIBS[@]}"; do
    if [ ! -f "$PREBUILT_DIR/$lib" ]; then
        MISSING_LIBS+=("$lib")
    fi
done

if [ ${#MISSING_LIBS[@]} -gt 0 ]; then
    echo "Error: Missing essential libraries:"
    for lib in "${MISSING_LIBS[@]}"; do
        echo "  - $lib"
    done
    echo ""
    echo "Please run build-dependencies.sh first to build these libraries"
    exit 1
fi

# Check for optional libraries and report what's available
OPTIONAL_LIBS=(
    "lib/libvorbis.a:Vorbis audio codec"
    "lib/libvorbisenc.a:Vorbis encoder"
    "lib/libogg.a:Ogg container format"
    "lib/libtheora.a:Theora video codec"
    "lib/libtheoraenc.a:Theora encoder"
    "lib/libtheoradec.a:Theora decoder"
    "lib/libmp3lame.a:LAME MP3 encoder"
    "lib/libopus.a:Opus audio codec"
    "lib/libSvtAv1Enc.a:SVT-AV1 encoder"
)

echo "Checking for optional libraries..."
AVAILABLE_OPTIONAL=()
for lib_info in "${OPTIONAL_LIBS[@]}"; do
    lib_path=$(echo "$lib_info" | cut -d: -f1)
    lib_desc=$(echo "$lib_info" | cut -d: -f2)
    if [ -f "$PREBUILT_DIR/$lib_path" ]; then
        AVAILABLE_OPTIONAL+=("$lib_desc")
        echo "  ✓ $lib_desc"
    else
        echo "  ✗ $lib_desc (not available)"
    fi
done

echo ""
echo "Building with ${#AVAILABLE_OPTIONAL[@]} optional codecs available"
echo ""

# Build the AAR
echo "Starting AAR build..."
./gradlew assembleRelease

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Build successful!"
    echo ""
    echo "HandBrake Android AAR built with full functionality:"
    echo "  - Essential codecs: x264, x265, FFmpeg"
    echo "  - Optional codecs: ${#AVAILABLE_OPTIONAL[@]} available"
    echo ""
    echo "Output AAR: build/outputs/aar/android-handbrake-release.aar"
    
    # Show AAR info
    AAR_FILE="build/outputs/aar/android-handbrake-release.aar"
    if [ -f "$AAR_FILE" ]; then
        AAR_SIZE=$(ls -lh "$AAR_FILE" | awk '{print $5}')
        echo "AAR size: $AAR_SIZE"
        
        # Show what's inside the AAR
        echo ""
        echo "AAR contents:"
        unzip -l "$AAR_FILE" | grep "\.so$" | awk '{print "  - " $4}'
    fi
    
    echo ""
    echo "Full HandBrake functionality is now available in the AAR!"
    echo "You can now use this AAR in Android projects for video transcoding."
else
    echo ""
    echo "✗ Build failed!"
    echo "Check the output above for error details"
    exit 1
fi
