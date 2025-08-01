# Git LFS Setup for HandBrake Android

## Problem
GitHub rejected the push because `libavcodec.a` (134.94 MB) exceeds the 100MB file size limit.

## Solution: Set up Git LFS

### 1. Install Git LFS (if not already installed)
```bash
# On macOS with Homebrew
brew install git-lfs

# Or download from https://git-lfs.github.com/
```

### 2. Initialize Git LFS in your repository
```bash
cd /Volumes/KINGSTON/_kingston_misc/handbrake_android
git lfs install
```

### 3. Track large files with LFS
```bash
# Track all .a files (static libraries)
git lfs track "*.a"

# Track all .so files (shared libraries) 
git lfs track "*.so"

# Track other large binary files
git lfs track "*.zip"
git lfs track "*.tar.gz"
git lfs track "*.aar"

# Specifically track the prebuilt directory
git lfs track "android-handbrake/src/main/cpp/prebuilt/**/*.a"
git lfs track "android-handbrake/src/main/cpp/prebuilt/**/*.so"
```

### 4. Add the .gitattributes file
```bash
git add .gitattributes
git commit -m "Add Git LFS tracking for large binary files"
```

### 5. Remove large files from Git history and re-add with LFS
```bash
# Remove the large files from the current commit
git rm --cached android-handbrake/src/main/cpp/prebuilt/arm64-v8a/lib/*.a
git rm --cached android-handbrake/src/main/cpp/prebuilt/arm64-v8a/lib/*.so

# Commit the removal
git commit -m "Remove large binary files before LFS setup"

# Re-add the files (they'll now be tracked by LFS)
git add android-handbrake/src/main/cpp/prebuilt/arm64-v8a/lib/*.a
git add android-handbrake/src/main/cpp/prebuilt/arm64-v8a/lib/*.so

# Commit with LFS
git commit -m "Add large binary files with Git LFS"
```

### 6. Push to GitHub
```bash
git push origin main
```

## Alternative: Exclude Large Files
If you prefer not to use LFS, you can exclude the prebuilt libraries:

### Add to .gitignore
```
# Exclude prebuilt libraries (too large for GitHub)
android-handbrake/src/main/cpp/prebuilt/
android-handbrake/downloads/
```

### Remove from tracking
```bash
git rm -r --cached android-handbrake/src/main/cpp/prebuilt/
git rm -r --cached android-handbrake/downloads/
echo "android-handbrake/src/main/cpp/prebuilt/" >> .gitignore
echo "android-handbrake/downloads/" >> .gitignore
git add .gitignore
git commit -m "Exclude large prebuilt libraries from Git"
git push origin main
```

## Recommended Approach

For this project, I recommend **excluding the prebuilt libraries** since:

1. They can be rebuilt using the build scripts
2. They're platform-specific (arm64-v8a only)
3. They take up significant space (hundreds of MB)
4. The build process is documented and reproducible

## Files to Keep in Git
- Source code
- Build scripts (build-dependencies.sh, build-full.sh, etc.)
- CMakeLists.txt and build configuration
- Documentation
- Small example files

## Files to Exclude
- Prebuilt static libraries (*.a files)
- Downloaded source archives
- Build artifacts
- Generated AAR files

This approach keeps the repository clean and focuses on the source code and build process rather than large binary artifacts.
