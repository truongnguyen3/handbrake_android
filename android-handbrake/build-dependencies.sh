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

# ABI targets - Start with just arm64-v8a for faster testing
ABIS=("arm64-v8a")
# Full list: ABIS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")

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
    NPROC=$(sysctl -n hw.ncpu)
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    NDK_HOST="linux-x86_64"
    NPROC=$(nproc)
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
    export NM="$TOOLCHAIN/bin/llvm-nm"
    
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
            export ARCH="i686"
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
    # Updated LDFLAGS for NDK 26/27 compatibility - removed -lgcc and -static-libstdc++
    export LDFLAGS="-Wl,--exclude-libs,libgcc.a -Wl,--exclude-libs,libatomic.a -ldl"
    
    # Additional environment
    export PKG_CONFIG_LIBDIR="$TOOLCHAIN/sysroot/usr/lib/pkgconfig"
    export PATH="$TOOLCHAIN/bin:$PATH"
    
    # Verify toolchain paths exist
    if [ ! -f "$CC" ]; then
        echo "Error: Compiler not found at $CC"
        echo "Available files in $TOOLCHAIN/bin:"
        ls -la "$TOOLCHAIN/bin/" | grep clang || echo "No clang found"
        exit 1
    fi
    
    echo "Android toolchain configured for $abi:"
    echo "  CC: $CC"
    echo "  Target: $TARGET"
    echo "  Host: $CONFIGURE_HOST"
    
    # Test compiler
    echo "Testing compiler..."
    echo 'int main(){return 0;}' > test.c
    if ! $CC test.c -o test 2>/dev/null; then
        echo "Error: Compiler $CC is not working"
        echo "Available compilers in $TOOLCHAIN/bin:"
        ls $TOOLCHAIN/bin/*-clang* 2>/dev/null || echo "No clang compilers found"
        rm -f test.c test
        exit 1
    fi
    rm -f test.c test
    echo "Compiler test passed"
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
            
            # Set up x264-specific environment for NDK 26/27 compatibility
            export SYSROOT="$TOOLCHAIN/sysroot"
            export CROSS="$TOOLCHAIN/bin/$TARGET-"
            
            # Critical: x264 needs LD to be clang for NDK 26/27, not ld
            export CC="$TOOLCHAIN/bin/${TARGET}${ANDROID_API_LEVEL}-clang"
            export CXX="$TOOLCHAIN/bin/${TARGET}${ANDROID_API_LEVEL}-clang++"
            export LD="$CC"    # Important: x264 autoconf needs LD=clang for link tests
            export AS="$CC"
            export AR="$TOOLCHAIN/bin/llvm-ar"
            export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
            export STRIP="$TOOLCHAIN/bin/llvm-strip"
            export NM="$TOOLCHAIN/bin/llvm-nm"
            export PKG_CONFIG="/usr/bin/false"  # Disable host pkg-config
            
            # NDK 27 doesn't have target-specific strings, use llvm-strings
            export STRINGS="$TOOLCHAIN/bin/llvm-strings"
            
            # Add sysroot to flags for NDK compatibility
            export CFLAGS="$CFLAGS --sysroot=$SYSROOT -I$SYSROOT/usr/include"
            export LDFLAGS="$LDFLAGS --sysroot=$SYSROOT -L$SYSROOT/usr/lib"
            
            # Ensure NDK tools are first in PATH
            export PATH="$TOOLCHAIN/bin:$PATH"
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure x264 for Android with proper cross-compilation settings
            ./configure \
                --prefix="$PREFIX_PATH" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --enable-pic \
                --disable-cli \
                --disable-asm \
                --disable-thread \
                --disable-opencl
                
            if [ $? -ne 0 ]; then
                echo "x264 configure failed for $abi"
                echo "Checking x264 config.log for errors..."
                if [ -f config.log ]; then
                    echo "Last 20 lines of config.log:"
                    tail -20 config.log
                else
                    echo "config.log not found"
                fi
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "x264 build failed for $abi"
                exit 1
            fi
            
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
            
            # Clean previous builds
            rm -rf CMakeCache.txt CMakeFiles/
            
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
                  
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "x265 build failed for $abi"
                exit 1
            fi
            
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
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure FFmpeg for Android - BUILD STATIC LIBRARIES
            ./configure \
                --prefix="$PREFIX_PATH" \
                --enable-cross-compile \
                --target-os=android \
                --arch=$ARCH \
                --cpu=generic \
                --cc="$CC" \
                --cxx="$CXX" \
                --ar="$AR" \
                --ranlib="$RANLIB" \
                --strip="$STRIP" \
                --nm="$NM" \
                --disable-shared \
                --enable-static \
                --enable-pic \
                --disable-asm \
                --disable-doc \
                --disable-programs \
                --disable-ffmpeg \
                --disable-ffplay \
                --disable-ffprobe \
                --disable-avdevice \
                --enable-avfilter \
                --enable-avformat \
                --enable-avcodec \
                --enable-swscale \
                --enable-swresample \
                --disable-network \
                --disable-zlib \
                --disable-iconv \
                --disable-securetransport \
                --disable-videotoolbox \
                --extra-cflags="$CFLAGS -fPIC" \
                --extra-ldflags="$LDFLAGS"
                
            if [ $? -ne 0 ]; then
                echo "FFmpeg configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "FFmpeg build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "jansson")
            # Jansson build
            cd build/dependencies
            if [ ! -d "jansson" ]; then
                git clone https://github.com/akheron/jansson.git jansson
            fi
            cd jansson
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Generate configure script if it doesn't exist
            if [ ! -f configure ]; then
                echo "Generating configure script for jansson..."
                autoreconf -fiv
            fi
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure Jansson for Android
            ./configure \
                --prefix="$PREFIX_PATH" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --disable-shared \
                --disable-dependency-tracking \
                CC="$CC" \
                CXX="$CXX" \
                AR="$AR" \
                STRIP="$STRIP" \
                RANLIB="$RANLIB" \
                CFLAGS="$CFLAGS -I$TOOLCHAIN/sysroot/usr/include" \
                LDFLAGS="$LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib"
                
            if [ $? -ne 0 ]; then
                echo "jansson configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "jansson build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "lame")
            # LAME build
            cd build/dependencies
            if [ ! -d "lame" ]; then
                git clone https://github.com/rbrito/lame.git lame
            fi
            cd lame
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Generate configure script if it doesn't exist
            if [ ! -f configure ]; then
                echo "Generating configure script for lame..."
                autoreconf -fiv
            fi
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure LAME for Android
            ./configure \
                --prefix="$PREFIX_PATH" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --disable-shared \
                --disable-gtktest \
                --disable-frontend \
                CC="$CC" \
                CXX="$CXX" \
                AR="$AR" \
                STRIP="$STRIP" \
                RANLIB="$RANLIB" \
                CFLAGS="$CFLAGS -I$TOOLCHAIN/sysroot/usr/include" \
                LDFLAGS="$LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib"
                
            if [ $? -ne 0 ]; then
                echo "lame configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "lame build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "libogg")
            # libogg build
            cd build/dependencies
            if [ ! -d "libogg" ]; then
                git clone https://github.com/xiph/ogg.git libogg
            fi
            cd libogg
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Generate configure script if it doesn't exist
            if [ ! -f configure ]; then
                echo "Generating configure script for libogg..."
                autoreconf -fiv
            fi
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure libogg for Android
            ./configure \
                --prefix="$PREFIX_PATH" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --disable-shared \
                CC="$CC" \
                CXX="$CXX" \
                AR="$AR" \
                STRIP="$STRIP" \
                RANLIB="$RANLIB" \
                CFLAGS="$CFLAGS -I$TOOLCHAIN/sysroot/usr/include" \
                LDFLAGS="$LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib"
                
            if [ $? -ne 0 ]; then
                echo "libogg configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "libogg build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "libvorbis")
            # libvorbis build
            cd build/dependencies
            if [ ! -d "libvorbis" ]; then
                git clone https://github.com/xiph/vorbis.git libvorbis
            fi
            cd libvorbis
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Generate configure script if it doesn't exist
            if [ ! -f configure ]; then
                echo "Generating configure script for libvorbis..."
                autoreconf -fiv
            fi
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure libvorbis for Android
            ./configure \
                --prefix="$PREFIX_PATH" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --disable-shared \
                --disable-examples \
                --disable-oggtest \
                CC="$CC" \
                CXX="$CXX" \
                AR="$AR" \
                STRIP="$STRIP" \
                RANLIB="$RANLIB" \
                CFLAGS="$CFLAGS -I$TOOLCHAIN/sysroot/usr/include" \
                LDFLAGS="$LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib"
                
            if [ $? -ne 0 ]; then
                echo "libvorbis configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "libvorbis build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "libtheora")
            # libtheora build
            cd build/dependencies
            if [ ! -d "libtheora" ]; then
                git clone https://github.com/xiph/theora.git libtheora
            fi
            cd libtheora
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Generate configure script if it doesn't exist
            if [ ! -f configure ]; then
                echo "Generating configure script for libtheora..."
                autoreconf -fiv
            fi
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure libtheora for Android
            ./configure \
                --prefix="$PREFIX_PATH" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --disable-shared \
                --disable-examples \
                --disable-oggtest \
                --disable-vorbistest \
                CC="$CC" \
                CXX="$CXX" \
                AR="$AR" \
                STRIP="$STRIP" \
                RANLIB="$RANLIB" \
                CFLAGS="$CFLAGS -I$TOOLCHAIN/sysroot/usr/include" \
                LDFLAGS="$LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib"
                
            if [ $? -ne 0 ]; then
                echo "libtheora configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "libtheora build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "libjpeg-turbo")
            # libjpeg-turbo build using CMake
            cd build/dependencies
            if [ ! -d "libjpeg-turbo" ]; then
                git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git libjpeg-turbo
            fi
            
            # Create build directory for this ABI
            mkdir -p "libjpeg-turbo/build-$abi"
            cd "libjpeg-turbo/build-$abi"
            
            # Clean previous builds
            rm -rf CMakeCache.txt CMakeFiles/
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure libjpeg-turbo for Android
            cmake -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
                  -DANDROID_ABI=$abi \
                  -DANDROID_PLATFORM=android-$ANDROID_API_LEVEL \
                  -DCMAKE_BUILD_TYPE=Release \
                  -DCMAKE_INSTALL_PREFIX="$PREFIX_PATH" \
                  -DENABLE_SHARED=OFF \
                  -DENABLE_STATIC=ON \
                  -DWITH_SIMD=OFF \
                  -DWITH_JAVA=OFF \
                  -DCMAKE_SYSTEM_PROCESSOR=$ARCH \
                  ../
                  
            if [ $? -ne 0 ]; then
                echo "libjpeg-turbo cmake configure failed for $abi"
                exit 1
            fi
                  
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "libjpeg-turbo build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../../..
            ;;
            
        "zlib")
            # zlib build
            cd build/dependencies
            if [ ! -d "zlib" ]; then
                git clone https://github.com/madler/zlib.git zlib
            fi
            cd zlib
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # For zlib, we need to ensure NDK tools are used, not host tools
            # Create a custom Makefile approach since configure may detect wrong tools
            
            # First try configure and then fix the Makefile
            CHOST="$CONFIGURE_HOST" \
            CC="$CC" \
            CXX="$CXX" \
            AR="$AR" \
            STRIP="$STRIP" \
            RANLIB="$RANLIB" \
            CFLAGS="$CFLAGS" \
            LDFLAGS="$LDFLAGS" \
            ./configure \
                --prefix="$PREFIX_PATH" \
                --static
                
            # Force correct AR and RANLIB in Makefile regardless of what configure detected
            sed -i.bak "s|^AR=.*|AR=$AR|g" Makefile
            sed -i.bak "s|^ARFLAGS=.*|ARFLAGS=rcs|g" Makefile  
            sed -i.bak "s|^RANLIB=.*|RANLIB=$RANLIB|g" Makefile
            sed -i.bak "s|^CC=.*|CC=$CC|g" Makefile
            
            echo "Verifying Makefile uses correct tools:"
            echo "AR: $(grep '^AR=' Makefile)"
            echo "RANLIB: $(grep '^RANLIB=' Makefile)"
            echo "CC: $(grep '^CC=' Makefile)"
                
            if [ $? -ne 0 ]; then
                echo "zlib configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "zlib build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "bz2")
            # bzip2 build
            cd build/dependencies
            if [ ! -d "bzip2" ]; then
                git clone https://github.com/commontk/bzip2.git bzip2
            fi
            cd bzip2
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Build bzip2 for Android - only build the library, skip tests
            make CC="$CC" AR="$AR" RANLIB="$RANLIB" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" libbz2.a -j$NPROC
            if [ $? -ne 0 ]; then
                echo "bzip2 build failed for $abi"
                exit 1
            fi
            
            # Install manually
            mkdir -p "../../../src/main/cpp/prebuilt/$abi/include"
            mkdir -p "../../../src/main/cpp/prebuilt/$abi/lib"
            cp bzlib.h "../../../src/main/cpp/prebuilt/$abi/include/"
            cp libbz2.a "../../../src/main/cpp/prebuilt/$abi/lib/"
            
            cd ../../..
            ;;
            
        "opus")
            # Opus build
            cd build/dependencies
            if [ ! -d "opus" ]; then
                git clone https://github.com/xiph/opus.git opus
            fi
            cd opus
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Generate configure script if it doesn't exist
            if [ ! -f configure ]; then
                echo "Generating configure script for opus..."
                autoreconf -fiv
            fi
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure Opus for Android
            ./configure \
                --prefix="$PREFIX_PATH" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --disable-shared \
                --disable-extra-programs \
                --disable-doc \
                CC="$CC" \
                CXX="$CXX" \
                AR="$AR" \
                STRIP="$STRIP" \
                RANLIB="$RANLIB" \
                CFLAGS="$CFLAGS -I$TOOLCHAIN/sysroot/usr/include" \
                LDFLAGS="$LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib"
                
            if [ $? -ne 0 ]; then
                echo "opus configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "opus build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "svt-av1")
            # SVT-AV1 build
            cd build/dependencies
            if [ ! -d "SVT-AV1" ]; then
                git clone https://gitlab.com/AOMediaCodec/SVT-AV1.git SVT-AV1
            fi
            cd SVT-AV1
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Create build directory for this ABI
            mkdir -p "build-$abi"
            cd "build-$abi"
            
            # Configure SVT-AV1 for Android - disable assembly for compatibility
            cmake -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
                  -DANDROID_ABI=$abi \
                  -DANDROID_PLATFORM=android-$ANDROID_API_LEVEL \
                  -DCMAKE_BUILD_TYPE=Release \
                  -DCMAKE_INSTALL_PREFIX="../../../../src/main/cpp/prebuilt/$abi" \
                  -DENABLE_SHARED=OFF \
                  -DENABLE_CLI=OFF \
                  -DENABLE_TESTS=OFF \
                  -DENABLE_EXAMPLES=OFF \
                  -DENABLE_NASM=OFF \
                  -DCMAKE_SYSTEM_PROCESSOR=$ARCH \
                  ../
                  
            if [ $? -ne 0 ]; then
                echo "SVT-AV1 cmake configure failed for $abi"
                exit 1
            fi
                  
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "SVT-AV1 build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "libdvdread")
            # libdvdread build
            mkdir -p build/dependencies
            cd build/dependencies
            if [ ! -d "libdvdread" ]; then
                git clone https://code.videolan.org/videolan/libdvdread.git libdvdread
            fi
            cd libdvdread
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Generate configure script if it doesn't exist
            if [ ! -f configure ]; then
                echo "Generating configure script for libdvdread..."
                autoreconf -fiv
            fi
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure libdvdread for Android
            ./configure \
                --prefix="$PREFIX_PATH" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --disable-shared \
                --disable-apidoc \
                CC="$CC" \
                CXX="$CXX" \
                AR="$AR" \
                STRIP="$STRIP" \
                RANLIB="$RANLIB" \
                CFLAGS="$CFLAGS -I$TOOLCHAIN/sysroot/usr/include" \
                LDFLAGS="$LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib"
                
            if [ $? -ne 0 ]; then
                echo "libdvdread configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "libdvdread build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "libdvdnav")
            # libdvdnav build (depends on libdvdread)
            mkdir -p build/dependencies
            cd build/dependencies
            if [ ! -d "libdvdnav" ]; then
                git clone https://code.videolan.org/videolan/libdvdnav.git libdvdnav
            fi
            cd libdvdnav
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Generate configure script if it doesn't exist
            if [ ! -f configure ]; then
                echo "Generating configure script for libdvdnav..."
                autoreconf -fiv
            fi
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure libdvdnav for Android
            ./configure \
                --prefix="$PREFIX_PATH" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --disable-shared \
                --disable-apidoc \
                --with-dvdread-config="$PREFIX_PATH/bin/dvdread-config" \
                CC="$CC" \
                CXX="$CXX" \
                AR="$AR" \
                STRIP="$STRIP" \
                RANLIB="$RANLIB" \
                CFLAGS="$CFLAGS -I$TOOLCHAIN/sysroot/usr/include -I$PREFIX_PATH/include" \
                LDFLAGS="$LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib -L$PREFIX_PATH/lib"
                
            if [ $? -ne 0 ]; then
                echo "libdvdnav configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "libdvdnav build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
            
        "libbluray")
            # libbluray build
            mkdir -p build/dependencies
            cd build/dependencies
            if [ ! -d "libbluray" ]; then
                git clone https://code.videolan.org/videolan/libbluray.git libbluray
            fi
            cd libbluray
            
            # Clean previous builds
            make clean 2>/dev/null || true
            
            # Generate configure script if it doesn't exist
            if [ ! -f configure ]; then
                echo "Generating configure script for libbluray..."
                autoreconf -fiv
            fi
            
            # Get absolute path for prefix
            PREFIX_PATH=$(cd ../../../src/main/cpp/prebuilt/$abi && pwd)
            
            # Configure libbluray for Android
            ./configure \
                --prefix="$PREFIX_PATH" \
                --host="$CONFIGURE_HOST" \
                --enable-static \
                --disable-shared \
                --disable-examples \
                --disable-bdjava-jar \
                --disable-udf \
                --without-libxml2 \
                --without-freetype \
                CC="$CC" \
                CXX="$CXX" \
                AR="$AR" \
                STRIP="$STRIP" \
                RANLIB="$RANLIB" \
                CFLAGS="$CFLAGS -I$TOOLCHAIN/sysroot/usr/include" \
                LDFLAGS="$LDFLAGS -L$TOOLCHAIN/sysroot/usr/lib"
                
            if [ $? -ne 0 ]; then
                echo "libbluray configure failed for $abi"
                exit 1
            fi
                
            make -j$NPROC 2>/dev/null || make -j1
            if [ $? -ne 0 ]; then
                echo "libbluray build failed for $abi"
                exit 1
            fi
            
            make install
            cd ../../..
            ;;
    esac
}

# Build dependencies for each ABI
for abi in "${ABIS[@]}"; do
    echo "Building dependencies for $abi..."
    mkdir -p "src/main/cpp/prebuilt/$abi"
    mkdir -p "src/main/cpp/prebuilt/$abi/include"
    mkdir -p "src/main/cpp/prebuilt/$abi/lib"
    
    # Build each dependency
    build_dependency "x264" "$abi"
    build_dependency "x265" "$abi"
    build_dependency "ffmpeg" "$abi"
    build_dependency "jansson" "$abi"
    build_dependency "lame" "$abi"
    build_dependency "libogg" "$abi"
    build_dependency "libvorbis" "$abi"
    build_dependency "libtheora" "$abi"
    build_dependency "libjpeg-turbo" "$abi"
    build_dependency "zlib" "$abi"
    build_dependency "bz2" "$abi"
    build_dependency "opus" "$abi"
    build_dependency "svt-av1" "$abi"
    build_dependency "libdvdread" "$abi"
    build_dependency "libdvdnav" "$abi" 
    build_dependency "libbluray" "$abi"
done

echo "Dependency build completed!"
echo ""
echo "To build the AAR file, run:"
echo "./gradlew assembleRelease"