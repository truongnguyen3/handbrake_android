#!/bin/bash

# Build only the missing DVD/BluRay dependencies
set -e

# Source the main build script functions
source ./build-dependencies.sh

# Only build the missing dependencies for arm64-v8a
ABI="arm64-v8a"

echo "Building missing DVD/BluRay dependencies for $ABI..."

# Create required directories
mkdir -p "src/main/cpp/prebuilt/$ABI"
mkdir -p "src/main/cpp/prebuilt/$ABI/include"
mkdir -p "src/main/cpp/prebuilt/$ABI/lib"

# Build missing dependencies
build_dependency "libdvdread" "$ABI"
build_dependency "libdvdnav" "$ABI" 
build_dependency "libbluray" "$ABI"

echo "Missing dependencies build completed!"
