# CMakeLists.txt for HandBrake Android AAR
cmake_minimum_required(VERSION 3.22.1)

project("handbrake-android")

# Set C/C++ standards
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Android-specific settings
set(CMAKE_ANDROID_ARCH_ABI ${ANDROID_ABI})
set(CMAKE_ANDROID_NDK ${ANDROID_NDK})
set(CMAKE_TOOLCHAIN_FILE ${ANDROID_NDK}/build/cmake/android.toolchain.cmake)

# Define HandBrake source paths (using copied source)
set(HANDBRAKE_SRC "${CMAKE_CURRENT_SOURCE_DIR}/handbrake-source")
set(PREBUILT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/prebuilt/${ANDROID_ABI}")

# Include directories
include_directories(
    ${HANDBRAKE_SRC}
    ${HANDBRAKE_SRC}/handbrake
    ${PREBUILT_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/jni
)

# Compiler flags for Android
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DANDROID -D__ANDROID__ -fPIC")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DANDROID -D__ANDROID__ -fPIC")

# Find required libraries
find_library(log-lib log)
find_library(android-lib android)

# Core HandBrake source files (minimal working set - only files that compile)
set(HANDBRAKE_SOURCES
    ${HANDBRAKE_SRC}/lang.c
    ${HANDBRAKE_SRC}/colormap.c
    # Only include files with minimal dependencies for now
)

# JNI wrapper sources (using minimal bridge)
set(JNI_SOURCES
    jni/handbrake_jni.cpp
    jni/handbrake_bridge_minimal.cpp
)

# Pre-built dependencies (you'll need to build these separately)
# These should be built using Android NDK for each ABI
set(PREBUILT_LIBS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/prebuilt/${ANDROID_ABI}")

# Link pre-built libraries (using stub libraries for now)
add_library(x264 STATIC IMPORTED)
set_target_properties(x264 PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libx264.a)

add_library(x265 STATIC IMPORTED)
set_target_properties(x265 PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libx265.a)

add_library(avcodec STATIC IMPORTED)
set_target_properties(avcodec PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libavcodec.a)

add_library(avformat STATIC IMPORTED)
set_target_properties(avformat PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libavformat.a)

add_library(avutil STATIC IMPORTED)
set_target_properties(avutil PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libavutil.a)

add_library(swscale STATIC IMPORTED)
set_target_properties(swscale PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libswscale.a)

# Create the main HandBrake library
add_library(handbrake-core STATIC ${HANDBRAKE_SOURCES})

# Create the JNI shared library
add_library(handbrake-android SHARED ${JNI_SOURCES})

# Link libraries
target_link_libraries(handbrake-android
    handbrake-core
    avcodec
    avformat
    avutil
    swscale
    x264
    x265
    ${log-lib}
    ${android-lib}
)

# Preprocessor definitions
target_compile_definitions(handbrake-core PRIVATE
    __LIBHB__
    ANDROID
    USE_PTHREAD
    HB_VERSION_MAJOR=1
    HB_VERSION_MINOR=8
    HB_VERSION_POINT=0
)

target_compile_definitions(handbrake-android PRIVATE
    __LIBHB__
    ANDROID
)