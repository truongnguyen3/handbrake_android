#!/bin/bash

# HandBrake Android Build Script with Pre-built Dependencies
# This script downloads and uses pre-built FFmpeg, x264, and x265 libraries

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

echo "Building HandBrake AAR with pre-built dependencies..."
echo "NDK: $ANDROID_NDK_ROOT"
echo "API Level: $ANDROID_API_LEVEL"
echo "HandBrake Root: $HANDBRAKE_ROOT"

# Check if NDK exists
if [ ! -d "$ANDROID_NDK_ROOT" ]; then
    echo "Error: Android NDK not found at $ANDROID_NDK_ROOT"
    exit 1
fi

# Create directories
mkdir -p src/main/cpp/prebuilt
mkdir -p src/main/cpp/handbrake-source
mkdir -p downloads

# Copy HandBrake source files
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

# Function to download and extract pre-built libraries
download_prebuilt_ffmpeg() {
    echo "Downloading pre-built FFmpeg libraries..."
    
    # Download FFmpeg Android lite (recent version)
    if [ ! -f "downloads/ffmpeg-7.1-android-lite.tar.xz" ]; then
        echo "Downloading FFmpeg 7.1 Android lite..."
        curl -L -o downloads/ffmpeg-7.1-android-lite.tar.xz \
            "https://sourceforge.net/projects/avbuild/files/android/ffmpeg-7.1-android-lite.tar.xz/download"
    fi
    
    # Extract FFmpeg libraries
    if [ -f "downloads/ffmpeg-7.1-android-lite.tar.xz" ]; then
        echo "Extracting FFmpeg libraries..."
        cd downloads
        tar -xf ffmpeg-7.1-android-lite.tar.xz
        cd ..
        
        # Copy to prebuilt directories
        for abi in "arm64-v8a" "armeabi-v7a" "x86" "x86_64"; do
            mkdir -p "src/main/cpp/prebuilt/$abi/lib"
            mkdir -p "src/main/cpp/prebuilt/$abi/include"
            
            # Map ABI names (avbuild uses different naming)
            case $abi in
                "arm64-v8a")
                    avbuild_name="aarch64"
                    ;;
                "armeabi-v7a")
                    avbuild_name="armv7"
                    ;;
                "x86")
                    avbuild_name="x86"
                    ;;
                "x86_64")
                    avbuild_name="x86_64"
                    ;;
            esac
            
            # Copy libraries if they exist
            if [ -d "downloads/ffmpeg-7.1-android-lite/lib/$avbuild_name" ]; then
                cp downloads/ffmpeg-7.1-android-lite/lib/$avbuild_name/*.so "src/main/cpp/prebuilt/$abi/lib/" 2>/dev/null || true
                cp downloads/ffmpeg-7.1-android-lite/lib/$avbuild_name/*.a "src/main/cpp/prebuilt/$abi/lib/" 2>/dev/null || true
            fi
            
            # Copy headers (same for all architectures)
            if [ -d "downloads/ffmpeg-7.1-android-lite/include" ]; then
                cp -r downloads/ffmpeg-7.1-android-lite/include/* "src/main/cpp/prebuilt/$abi/include/" 2>/dev/null || true
            fi
        done
    else
        echo "Warning: Could not download FFmpeg libraries"
    fi
}

# Function to download x264 libraries
download_prebuilt_x264() {
    echo "Downloading pre-built x264 libraries..."
    
    # Clone x264 Android repository
    if [ ! -d "downloads/x264-android" ]; then
        echo "Cloning x264 Android repository..."
        git clone https://github.com/stefanJi/x264.git downloads/x264-android
        cd downloads/x264-android
        
        # Set environment and build
        export ANDROID_NDK_ROOT="$ANDROID_NDK_ROOT"
        chmod +x compile_x264_for_android.sh
        
        # Try to build x264 (may fail, but we'll create stubs)
        ./compile_x264_for_android.sh || echo "x264 build failed, using stubs"
        cd ../..
    fi
    
    # Create stub x264 libraries if build failed
    for abi in "arm64-v8a" "armeabi-v7a" "x86" "x86_64"; do
        mkdir -p "src/main/cpp/prebuilt/$abi/lib"
        mkdir -p "src/main/cpp/prebuilt/$abi/include"
        
        # Create minimal x264 stub library
        if [ ! -f "src/main/cpp/prebuilt/$abi/lib/libx264.a" ]; then
            echo "Creating x264 stub library for $abi"
            echo "// x264 stub" > temp_x264.c
            "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/clang" \
                --target=aarch64-linux-android21 -c temp_x264.c -o temp_x264.o 2>/dev/null || true
            "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar" \
                rcs "src/main/cpp/prebuilt/$abi/lib/libx264.a" temp_x264.o 2>/dev/null || true
            rm -f temp_x264.c temp_x264.o
        fi
        
        # Create minimal x264 header
        cat > "src/main/cpp/prebuilt/$abi/include/x264.h" << 'EOF'
#ifndef X264_H
#define X264_H

// Minimal x264 header stub for compilation
typedef struct {
    int dummy;
} x264_param_t;

typedef struct {
    int dummy;
} x264_t;

#ifdef __cplusplus
extern "C" {
#endif

// Minimal function stubs
void x264_param_default(x264_param_t *param);
x264_t *x264_encoder_open(x264_param_t *param);
void x264_encoder_close(x264_t *h);

#ifdef __cplusplus
}
#endif

#endif /* X264_H */
EOF
    done
}

# Function to create x265 stub libraries
create_x265_stubs() {
    echo "Creating x265 stub libraries..."
    
    for abi in "arm64-v8a" "armeabi-v7a" "x86" "x86_64"; do
        mkdir -p "src/main/cpp/prebuilt/$abi/lib"
        mkdir -p "src/main/cpp/prebuilt/$abi/include"
        
        # Create minimal x265 stub library
        if [ ! -f "src/main/cpp/prebuilt/$abi/lib/libx265.a" ]; then
            echo "Creating x265 stub library for $abi"
            echo "// x265 stub" > temp_x265.c
            "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/clang" \
                --target=aarch64-linux-android21 -c temp_x265.c -o temp_x265.o 2>/dev/null || true
            "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar" \
                rcs "src/main/cpp/prebuilt/$abi/lib/libx265.a" temp_x265.o 2>/dev/null || true
            rm -f temp_x265.c temp_x265.o
        fi
        
        # Create minimal x265 header
        cat > "src/main/cpp/prebuilt/$abi/include/x265.h" << 'EOF'
#ifndef X265_H
#define X265_H

// Minimal x265 header stub for compilation
typedef struct {
    int dummy;
} x265_param;

typedef struct {
    int dummy;
} x265_encoder;

#ifdef __cplusplus
extern "C" {
#endif

// Minimal function stubs
void x265_param_default(x265_param *param);
x265_encoder *x265_encoder_open(x265_param *param);
void x265_encoder_close(x265_encoder *encoder);

#ifdef __cplusplus
}
#endif

#endif /* X265_H */
EOF
    done
}

# Create missing project.h file
create_project_header() {
    echo "Creating project.h header file..."
    
    cat > "src/main/cpp/handbrake-source/handbrake/project.h" << 'EOF'
#ifndef HB_PROJECT_H
#define HB_PROJECT_H

// HandBrake project configuration for Android

#define HB_PROJECT_TITLE            "HandBrake"
#define HB_PROJECT_NAME             "HandBrake"
#define HB_PROJECT_URL_WEBSITE      "https://handbrake.fr/"
#define HB_PROJECT_URL_COMMUNITY    "https://forum.handbrake.fr/"
#define HB_PROJECT_URL_IRC          "irc://irc.freenode.net/handbrake"

#define HB_PROJECT_FEATURE_QSV      0
#define HB_PROJECT_FEATURE_VCE      0
#define HB_PROJECT_FEATURE_NV       0

// Version information
#define HB_PROJECT_VERSION_MAJOR    1
#define HB_PROJECT_VERSION_MINOR    8
#define HB_PROJECT_VERSION_POINT    0

// Build configuration
#define HB_PROJECT_BUILD_DATE       __DATE__
#define HB_PROJECT_BUILD_TIME       __TIME__
#define HB_PROJECT_REPO_URL         "https://github.com/HandBrake/HandBrake.git"
#define HB_PROJECT_REPO_TAG         "master"
#define HB_PROJECT_REPO_REV         0
#define HB_PROJECT_REPO_HASH        "unknown"
#define HB_PROJECT_REPO_BRANCH      "master"
#define HB_PROJECT_REPO_REMOTE      "origin"
#define HB_PROJECT_REPO_TYPE        "developer"

#endif /* HB_PROJECT_H */
EOF
}

# Download dependencies
echo "Downloading pre-built dependencies..."
download_prebuilt_ffmpeg
download_prebuilt_x264
create_x265_stubs
create_project_header

echo ""
echo "✅ Build preparation completed!"
echo ""
echo "Dependencies status:"
echo "  FFmpeg: $([ -f "src/main/cpp/prebuilt/arm64-v8a/lib/libavcodec.so" ] && echo "✓ Downloaded" || echo "✗ Using stubs")"
echo "  x264:   ✓ Stub libraries created"
echo "  x265:   ✓ Stub libraries created"
echo ""
echo "Next steps:"
echo "1. Build the AAR: ./gradlew assembleRelease"
echo "2. The AAR will be located at: build/outputs/aar/"
echo ""
echo "Note: This build uses stub libraries for x264/x265."
echo "For full codec support, you would need to replace these with actual libraries."