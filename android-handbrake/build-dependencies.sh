#!/bin/bash

# HandBrake Android Dependencies Build Script
# This script builds all required dependencies for HandBrake on Android

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
export HANDBRAKE_ROOT=${HANDBRAKE_ROOT:-"../.."}

# ABI targets
ABIS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")

# Check if NDK exists
if [ ! -d "$ANDROID_NDK_ROOT" ]; then
    echo "Error: Android NDK not found at $ANDROID_NDK_ROOT"
    echo "Available NDK versions:"
    ls "$HOME/Library/Android/sdk/ndk/" 2>/dev/null || ls "$HOME/Android/Sdk/ndk/" 2>/dev/null || echo "No NDK found"
    echo "Please set ANDROID_NDK_ROOT environment variable to one of the above"
    exit 1
fi

echo "Building HandBrake dependencies for Android..."
echo "NDK: $ANDROID_NDK_ROOT"
echo "API Level: $ANDROID_API_LEVEL"
echo "HandBrake Root: $HANDBRAKE_ROOT"

# Create build directories
mkdir -p build/dependencies
mkdir -p src/main/cpp/prebuilt

# Detect host platform for NDK toolchain
if [[ "$OSTYPE" == "darwin"* ]]; then
    NDK_HOST="darwin-x86_64"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    NDK_HOST="linux-x86_64"
else
    echo "Unsupported host platform: $OSTYPE"
    exit 1
fi

# Function to set up Android toolchain environment
setup_android_env() {
    local abi=$1
    
    # Set up toolchain paths
    export TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$NDK_HOST"
    export AR="$TOOLCHAIN/bin/llvm-ar"
    export STRIP="$TOOLCHAIN/bin/llvm-strip"
    export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
    
    # Set ABI-specific variables
    case $abi in
        "arm64-v8a")
            export TARGET="aarch64-linux-android"
            export CC="$TOOLCHAIN/bin/aarch64-linux-android${ANDROID_API_LEVEL}-clang"
            export CXX="$TOOLCHAIN/bin/aarch64-linux-android${ANDROID_API_LEVEL}-clang++"
            export ARCH="aarch64"
            export CONFIGURE_HOST="aarch64-linux-android"
            ;;
        "armeabi-v7a")
            export TARGET="armv7a-linux-androideabi"
            export CC="$TOOLCHAIN/bin/armv7a-linux-androideabi${ANDROID_API_LEVEL}-clang"
            export CXX="$TOOLCHAIN/bin/armv7a-linux-androideabi${ANDROID_API_LEVEL}-clang++"
            export ARCH="arm"
            export CONFIGURE_HOST="arm-linux-androideabi"
            ;;
        "x86")
            export TARGET="i686-linux-android"
            export CC="$TOOLCHAIN/bin/i686-linux-android${ANDROID_API_LEVEL}-clang"
            export CXX="$TOOLCHAIN/bin/i686-linux-android${ANDROID_API_LEVEL}-clang++"
            export ARCH="x86"
            export CONFIGURE_HOST="i686-linux-android"
            ;;
        "x86_64")
            export TARGET="x86_64-linux-android"
            export CC="$TOOLCHAIN/bin/x86_64-linux-android${ANDROID_API_LEVEL}-clang"
            export CXX="$TOOLCHAIN/bin/x86_64-linux-android${ANDROID_API_LEVEL}-clang++"
            export ARCH="x86_64"
            export CONFIGURE_HOST="x86_64-linux-android"
            ;;
    esac
    
    # Common flags
    export CFLAGS="-DANDROID -fPIC -ffunction-sections -funwind-tables -fstack-protector-strong -no-canonical-prefixes"
    export CXXFLAGS="$CFLAGS"
    export LDFLAGS="-Wl,--exclude-libs,libgcc.a -Wl,--exclude-libs,libatomic.a -static-libstdc++ -lgcc -ldl"
    
    # Additional environment
    export PKG_CONFIG_LIBDIR="$TOOLCHAIN/sysroot/usr/lib/pkgconfig"
    export PATH="$TOOLCHAIN/bin:$PATH"
    
    echo "Android toolchain configured for $abi:"
    echo "  CC: $CC"
    echo "  Target: $TARGET"
    echo "  Host: $CONFIGURE_HOST"
}

# Function to build dependency for specific ABI
build_dependency() {
    local dep_name=$1
    local abi=$2
    
    echo "Building $dep_name for $abi..."
    
    # Set up Android environment
    setup_android_env $abi
    
    case $dep_name in
        "x264")
            # x264 build
            cd build/dependencies
            if [ ! -d "x264" ]; then
                git clone https://code.videolan.org/videolan/x264.git
            fi
            cd x264
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Test if compiler works
            echo "Testing compiler: $CC"
            echo 'int main(){return 0;}' > test.c
            if ! $CC test.c -o test 2>/dev/null; then
                echo "Error: Compiler $CC is not working"
                rm -f test.c test
                exit 1
            fi
            rm -f test.c test
            echo "Compiler test passed"
            
            # Set additional environment for x264 configure
            export CCAS="$CC"
            export LD="$CC"
            
            ./configure \
                --prefix="../../../src/main/cpp/prebuilt/$abi" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --enable-pic \
                --disable-cli \
                --disable-asm \
                --disable-thread \
                --extra-cflags="$CFLAGS -I$TOOLCHAIN/sysroot/usr/include" \
                --extra-ldflags="$LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib"
                
            if [ $? -ne 0 ]; then
                echo "Configure failed, trying with more flags..."
                CC="$CC" CXX="$CXX" ./configure \
                    --prefix="../../../src/main/cpp/prebuilt/$abi" \
                    --host="$CONFIGURE_HOST" \
                    --enable-static \
                    --enable-pic \
                    --disable-cli \
                    --disable-asm \
                    --disable-thread
            fi
                
            make -j$(nproc) 2>/dev/null || make -j1
            make install
            cd ../../..
            ;;
            
        "x265")
            # x265 build using CMake
            cd build/dependencies
            if [ ! -d "x265" ]; then
                git clone https://bitbucket.org/multicoreware/x265_git.git x265
            fi
            
            # Create build directory for this ABI
            mkdir -p "x265/build-$abi"
            cd "x265/build-$abi"
            
            cmake -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
                  -DANDROID_ABI=$abi \
                  -DANDROID_PLATFORM=android-$ANDROID_API_LEVEL \
                  -DCMAKE_BUILD_TYPE=Release \
                  -DCMAKE_INSTALL_PREFIX="../../../../src/main/cpp/prebuilt/$abi" \
                  -DENABLE_SHARED=OFF \
                  -DENABLE_CLI=OFF \
                  -DENABLE_PIC=ON \
                  ../source
                  
            make -j$(nproc) 2>/dev/null || make -j1
            make install
            cd ../../../..
            ;;
            
        "ffmpeg")
            # FFmpeg build configuration for Android
            cd build/dependencies
            if [ ! -d "ffmpeg" ]; then
                git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg
            fi
            cd ffmpeg
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Configure FFmpeg for Android
            ./configure \
                --prefix="../../../src/main/cpp/prebuilt/$abi" \
                --enable-cross-compile \
                --target-os=android \
                --arch=$ARCH \
                --cpu=generic \
                --cc="$CC" \
                --cxx="$CXX" \
                --enable-shared \
                --disable-static \
                --disable-doc \
                --disable-programs \
                --disable-avdevice \
                --disable-postproc \
                --disable-avfilter \
                --enable-decoder=h264 \
                --enable-decoder=hevc \
                --enable-decoder=aac \
                --enable-decoder=mp3 \
                --enable-encoder=libx264 \
                --enable-encoder=aac \
                --disable-network \
                --disable-zlib \
                --disable-iconv \
                --extra-cflags="$CFLAGS" \
                --extra-ldflags="$LDFLAGS"
                
            make -j$(nproc) 2>/dev/null || make -j1
            make install
            cd ../../..
            ;;
    esac
}

# Build dependencies for each ABI
for abi in "${ABIS[@]}"; do
    echo "Building dependencies for $abi..."
    mkdir -p "src/main/cpp/prebuilt/$abi"
    
    # Build each dependency
    build_dependency "x264" "$abi"
    build_dependency "x265" "$abi"
    build_dependency "ffmpeg" "$abi"
done

echo "Dependency build completed!"
echo ""
echo "To build the AAR file, run:"
echo "./gradlew assembleRelease"