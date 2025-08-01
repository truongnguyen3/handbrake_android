#!/bin/bash

# Test script to build only x265 for Android
set -e

export ANDROID_NDK_ROOT="/Users/jeremynguyen/Library/Android/sdk/ndk/27.1.12297006"
export ANDROID_API_LEVEL=21
abi="arm64-v8a"

# Detect host platform for NDK toolchain
if [[ "$OSTYPE" == "darwin"* ]]; then
    NDK_HOST="darwin-x86_64"
    NPROC=$(sysctl -n hw.ncpu)
else
    NDK_HOST="linux-x86_64"
    NPROC=$(nproc)
fi

# Set up toolchain paths
export TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$NDK_HOST"
export TARGET="aarch64-linux-android"
export ARCH="aarch64"
export CONFIGURE_HOST="aarch64-linux-android"

echo "Testing x265 build for Android..."
echo "NDK: $ANDROID_NDK_ROOT"
echo "Toolchain: $TOOLCHAIN"

# Create build directories
mkdir -p build/dependencies
mkdir -p src/main/cpp/prebuilt/$abi

# x265 build using CMake
cd build/dependencies
if [ ! -d "x265" ]; then
    echo "Cloning x265..."
    git clone https://bitbucket.org/multicoreware/x265_git.git x265
fi

# Create build directory for this ABI
mkdir -p "x265/build-$abi"
cd "x265/build-$abi"

# Clean previous builds
rm -rf CMakeCache.txt CMakeFiles/

echo "Configuring x265 with CMake..."

# Configure x265 for Android - disable assembly to avoid CPU target issues
cmake -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
      -DANDROID_ABI=$abi \
      -DANDROID_PLATFORM=android-$ANDROID_API_LEVEL \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="../../../../src/main/cpp/prebuilt/$abi" \
      -DENABLE_SHARED=OFF \
      -DENABLE_CLI=OFF \
      -DENABLE_PIC=ON \
      -DHIGH_BIT_DEPTH=OFF \
      -DENABLE_HDR10_PLUS=OFF \
      -DENABLE_ASSEMBLY=OFF \
      -DCROSS_COMPILE_ARM=ON \
      -DCMAKE_SYSTEM_PROCESSOR=$ARCH \
      ../source

if [ $? -ne 0 ]; then
    echo "x265 cmake configure failed for $abi"
    exit 1
fi

echo "Building x265..."
make -j2

if [ $? -ne 0 ]; then
    echo "x265 build failed for $abi"
    exit 1
fi

echo "x265 build successful!"
