#!/bin/bash

# Quick test script to verify x264 build works
# Run this before running the full build-dependencies.sh

set -e

export ANDROID_NDK_ROOT="$HOME/Library/Android/sdk/ndk/27.1.12297006"
export ANDROID_API_LEVEL=21

echo "Testing x264 build only..."
echo "NDK: $ANDROID_NDK_ROOT"

# Create minimal build structure
mkdir -p build/dependencies
mkdir -p src/main/cpp/prebuilt/arm64-v8a

# Just test arm64-v8a
ABI="arm64-v8a"
NDK_HOST="darwin-x86_64"

# Set up environment
TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$NDK_HOST"
TARGET="aarch64-linux-android"
CONFIGURE_HOST="aarch64-linux-android"

echo "Toolchain: $TOOLCHAIN"
echo "Target: $TARGET"

# Test if toolchain exists
if [ ! -d "$TOOLCHAIN" ]; then
    echo "Error: Toolchain not found at $TOOLCHAIN"
    exit 1
fi

# Set up x264-specific environment
export SYSROOT="$TOOLCHAIN/sysroot"
export CROSS="$TOOLCHAIN/bin/$TARGET-"
export CC="$TOOLCHAIN/bin/${TARGET}${ANDROID_API_LEVEL}-clang"
export CXX="$TOOLCHAIN/bin/${TARGET}${ANDROID_API_LEVEL}-clang++"
export LD="$CC"
export AS="$CC"
export AR="$TOOLCHAIN/bin/llvm-ar"
export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
export STRIP="$TOOLCHAIN/bin/llvm-strip"
export NM="$TOOLCHAIN/bin/llvm-nm"
export PKG_CONFIG="/usr/bin/false"
export STRINGS="$TOOLCHAIN/bin/llvm-strings"

# Flags
export CFLAGS="-DANDROID -fPIC --sysroot=$SYSROOT -I$SYSROOT/usr/include"
export LDFLAGS="--sysroot=$SYSROOT -L$SYSROOT/usr/lib"
export PATH="$TOOLCHAIN/bin:$PATH"

echo "Testing compiler: $CC"
echo 'int main(){return 0;}' > test.c
if ! $CC test.c -o test 2>/dev/null; then
    echo "Error: Compiler test failed"
    exit 1
fi
rm -f test.c test
echo "✓ Compiler test passed"

# Clone and test x264 configure
cd build/dependencies
if [ ! -d "x264" ]; then
    echo "Cloning x264..."
    git clone https://code.videolan.org/videolan/x264.git
fi
cd x264

echo "Testing x264 configure..."
./configure \
    --prefix="../../../src/main/cpp/prebuilt/$ABI" \
    --host="$CONFIGURE_HOST" \
    --enable-static \
    --enable-pic \
    --disable-cli \
    --disable-asm \
    --disable-thread \
    --disable-opencl

if [ $? -eq 0 ]; then
    echo "✓ x264 configure succeeded!"
    echo "Now you can run the full build-dependencies.sh script"
else
    echo "✗ x264 configure failed"
    echo "Config.log contents:"
    cat config.log
fi
