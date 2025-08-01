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

# HandBrake project configuration macros
add_definitions(
    -DHB_PROJECT_REPO_OFFICIAL=1
    -DHB_PROJECT_VERSION="1.8.0"
    -DHB_PROJECT_REPO_DATE="2024-08-01"
    -DHB_PROJECT_HOST_SYSTEMF="Android"
    -DHB_PROJECT_HOST_ARCH="${ANDROID_ABI}"
    -DHB_PROJECT_BUILD=20240801
    -DUSE_HB_ANDROID=1
    -DHB_PROJECT_FEATURE_LIBDVDNAV=0
    -DHB_PROJECT_FEATURE_LIBDVDREAD=0
    -DHB_PROJECT_FEATURE_LIBBLURAY=0
)

# Find required libraries
find_library(log-lib log)
find_library(android-lib android)

# Core HandBrake source files - Complete libhb functionality
set(HANDBRAKE_SOURCES
    # Core HandBrake files
    ${HANDBRAKE_SRC}/hb.c
    ${HANDBRAKE_SRC}/common.c
    ${HANDBRAKE_SRC}/lang.c
    ${HANDBRAKE_SRC}/colormap.c
    ${HANDBRAKE_SRC}/hbffmpeg.c
    ${HANDBRAKE_SRC}/param.c
    ${HANDBRAKE_SRC}/preset.c
    ${HANDBRAKE_SRC}/ports.c
    
    # JSON and Dictionary support
    ${HANDBRAKE_SRC}/hb_dict.c
    ${HANDBRAKE_SRC}/hb_json.c
    
    # Scanning and reading
    ${HANDBRAKE_SRC}/scan.c
    ${HANDBRAKE_SRC}/reader.c
    ${HANDBRAKE_SRC}/stream.c
    # DVD/BluRay support disabled for Android
    # ${HANDBRAKE_SRC}/bd.c
    # ${HANDBRAKE_SRC}/dvd.c  
    # ${HANDBRAKE_SRC}/dvdnav.c
    ${HANDBRAKE_SRC}/batch.c
    
    # Video processing
    ${HANDBRAKE_SRC}/sync.c
    ${HANDBRAKE_SRC}/work.c
    ${HANDBRAKE_SRC}/workpass.c
    ${HANDBRAKE_SRC}/fifo.c
    ${HANDBRAKE_SRC}/taskset.c
    
    # Video decoding
    ${HANDBRAKE_SRC}/decavcodec.c
    ${HANDBRAKE_SRC}/hwaccel.c
    
    # Video encoding
    ${HANDBRAKE_SRC}/encavcodec.c
    ${HANDBRAKE_SRC}/encx264.c
    ${HANDBRAKE_SRC}/encx265.c
    # ${HANDBRAKE_SRC}/encsvtav1.c  # Disabled for Android to avoid SVT-AV1 dependencies
    ${HANDBRAKE_SRC}/enctheora.c
    
    # Audio processing
    ${HANDBRAKE_SRC}/audio_remap.c
    ${HANDBRAKE_SRC}/audio_resample.c
    ${HANDBRAKE_SRC}/declpcm.c
    ${HANDBRAKE_SRC}/encavcodecaudio.c
    ${HANDBRAKE_SRC}/encvorbis.c
    
    # Video filters
    ${HANDBRAKE_SRC}/avfilter.c
    ${HANDBRAKE_SRC}/hbavfilter.c
    ${HANDBRAKE_SRC}/detelecine.c
    ${HANDBRAKE_SRC}/comb_detect.c
    ${HANDBRAKE_SRC}/decomb.c
    ${HANDBRAKE_SRC}/deinterlace.c
    ${HANDBRAKE_SRC}/deblock.c
    ${HANDBRAKE_SRC}/denoise.c
    ${HANDBRAKE_SRC}/nlmeans.c
    ${HANDBRAKE_SRC}/nlmeans_x86.c
    ${HANDBRAKE_SRC}/chroma_smooth.c
    ${HANDBRAKE_SRC}/lapsharp.c
    ${HANDBRAKE_SRC}/unsharp.c
    ${HANDBRAKE_SRC}/rotate.c
    ${HANDBRAKE_SRC}/pad.c
    ${HANDBRAKE_SRC}/cropscale.c
    ${HANDBRAKE_SRC}/grayscale.c
    ${HANDBRAKE_SRC}/colorspace.c
    ${HANDBRAKE_SRC}/vfr.c
    ${HANDBRAKE_SRC}/blend.c
    
    # Subtitle support (disabled for Android - libass dependency)
    ${HANDBRAKE_SRC}/decsrtsub.c
    ${HANDBRAKE_SRC}/decssasub.c
    ${HANDBRAKE_SRC}/dectx3gsub.c
    ${HANDBRAKE_SRC}/enctx3gsub.c
    ${HANDBRAKE_SRC}/decavsub.c
    ${HANDBRAKE_SRC}/encavsub.c
    # ${HANDBRAKE_SRC}/rendersub.c - requires libass
    ${HANDBRAKE_SRC}/ssautil.c
    
    # Muxing
    ${HANDBRAKE_SRC}/muxavformat.c
    ${HANDBRAKE_SRC}/muxcommon.c
    ${HANDBRAKE_SRC}/demuxmpeg.c
    
    # Video processing utilities
    ${HANDBRAKE_SRC}/bitstream.c
    ${HANDBRAKE_SRC}/nal_units.c
    ${HANDBRAKE_SRC}/extradata.c
    ${HANDBRAKE_SRC}/motion_metric.c
    ${HANDBRAKE_SRC}/mt_frame_filter.c
    
    # HDR and advanced video
    ${HANDBRAKE_SRC}/hdr10plus.c
    ${HANDBRAKE_SRC}/dovi_common.c
    ${HANDBRAKE_SRC}/rpu.c
    
    # Hardware acceleration (conditional)
    ${HANDBRAKE_SRC}/qsv_common.c
    ${HANDBRAKE_SRC}/nvenc_common.c
    ${HANDBRAKE_SRC}/vce_common.c
    ${HANDBRAKE_SRC}/mf_common.c
    
    # Other utilities
    ${HANDBRAKE_SRC}/compat.c
    ${HANDBRAKE_SRC}/format.c
    ${HANDBRAKE_SRC}/eedi2.c
    
    # Android stubs for disabled features
    ${HANDBRAKE_SRC}/android_stubs.c
)

# JNI wrapper sources (using full HandBrake bridge)
set(JNI_SOURCES
    jni/handbrake_jni.cpp
    jni/handbrake_bridge.cpp
)

# Pre-built dependencies (you'll need to build these separately)
# These should be built using Android NDK for each ABI
set(PREBUILT_LIBS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/prebuilt/${ANDROID_ABI}")

# Link pre-built libraries - Complete HandBrake dependencies
# Core video codecs (required)
add_library(x264 STATIC IMPORTED)
set_target_properties(x264 PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libx264.a)

add_library(x265 STATIC IMPORTED)
set_target_properties(x265 PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libx265.a)

# FFmpeg libraries (required)
add_library(avcodec STATIC IMPORTED)
set_target_properties(avcodec PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libavcodec.a)

add_library(avformat STATIC IMPORTED)
set_target_properties(avformat PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libavformat.a)

add_library(avutil STATIC IMPORTED)
set_target_properties(avutil PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libavutil.a)

add_library(avfilter STATIC IMPORTED)
set_target_properties(avfilter PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libavfilter.a)

add_library(swscale STATIC IMPORTED)
set_target_properties(swscale PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libswscale.a)

add_library(swresample STATIC IMPORTED)
set_target_properties(swresample PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libswresample.a)

# Audio codecs (optional - check if files exist)
if(EXISTS ${PREBUILT_DIR}/lib/libvorbis.a)
    add_library(vorbis STATIC IMPORTED)
    set_target_properties(vorbis PROPERTIES IMPORTED_LOCATION
        ${PREBUILT_DIR}/lib/libvorbis.a)
    set(HAS_VORBIS TRUE)
endif()

if(EXISTS ${PREBUILT_DIR}/lib/libvorbisenc.a)
    add_library(vorbisenc STATIC IMPORTED)
    set_target_properties(vorbisenc PROPERTIES IMPORTED_LOCATION
        ${PREBUILT_DIR}/lib/libvorbisenc.a)
    set(HAS_VORBISENC TRUE)
endif()

if(EXISTS ${PREBUILT_DIR}/lib/libogg.a)
    add_library(ogg STATIC IMPORTED)
    set_target_properties(ogg PROPERTIES IMPORTED_LOCATION
        ${PREBUILT_DIR}/lib/libogg.a)
    set(HAS_OGG TRUE)
endif()

if(EXISTS ${PREBUILT_DIR}/lib/libtheora.a)
    add_library(theora STATIC IMPORTED)
    set_target_properties(theora PROPERTIES IMPORTED_LOCATION
        ${PREBUILT_DIR}/lib/libtheora.a)
    set(HAS_THEORA TRUE)
endif()

if(EXISTS ${PREBUILT_DIR}/lib/libtheoraenc.a)
    add_library(theoraenc STATIC IMPORTED)
    set_target_properties(theoraenc PROPERTIES IMPORTED_LOCATION
        ${PREBUILT_DIR}/lib/libtheoraenc.a)
    set(HAS_THEORAENC TRUE)
endif()

if(EXISTS ${PREBUILT_DIR}/lib/libtheoradec.a)
    add_library(theoradec STATIC IMPORTED)
    set_target_properties(theoradec PROPERTIES IMPORTED_LOCATION
        ${PREBUILT_DIR}/lib/libtheoradec.a)
    set(HAS_THEORADEC TRUE)
endif()

# Optional: LAME MP3 encoder
if(EXISTS ${PREBUILT_DIR}/lib/libmp3lame.a)
    add_library(mp3lame STATIC IMPORTED)
    set_target_properties(mp3lame PROPERTIES IMPORTED_LOCATION
        ${PREBUILT_DIR}/lib/libmp3lame.a)
    set(HAS_LAME TRUE)
endif()

# Optional: Opus codec
if(EXISTS ${PREBUILT_DIR}/lib/libopus.a)
    add_library(opus STATIC IMPORTED)
    set_target_properties(opus PROPERTIES IMPORTED_LOCATION
        ${PREBUILT_DIR}/lib/libopus.a)
    set(HAS_OPUS TRUE)
endif()

# Required: Jansson JSON library
add_library(jansson STATIC IMPORTED)
set_target_properties(jansson PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libjansson.a)

# Required: libjpeg-turbo
add_library(turbojpeg STATIC IMPORTED)
set_target_properties(turbojpeg PROPERTIES IMPORTED_LOCATION
    ${PREBUILT_DIR}/lib/libturbojpeg.a)

# Optional: SVT-AV1 encoder (disabled for Android)
# if(EXISTS ${PREBUILT_DIR}/lib/libSvtAv1Enc.so)
#     add_library(SvtAv1Enc SHARED IMPORTED)
#     set_target_properties(SvtAv1Enc PROPERTIES IMPORTED_LOCATION
#         ${PREBUILT_DIR}/lib/libSvtAv1Enc.so)
#     set(HAS_SVT_AV1 TRUE)
# endif()

# Create the main HandBrake library
add_library(handbrake-core STATIC ${HANDBRAKE_SOURCES})

# Create the JNI shared library
add_library(handbrake-android SHARED ${JNI_SOURCES})

# Link libraries - Complete HandBrake functionality
target_link_libraries(handbrake-android
    handbrake-core
    
    # FFmpeg libraries (required)
    avcodec
    avformat
    avutil
    avfilter
    swscale
    swresample
    
    # Video encoders (required)
    x264
    x265
    
    # Required core libraries
    jansson
    turbojpeg
    
    # System libraries
    ${log-lib}
    ${android-lib}
    
    # Standard C++ libraries
    z
    m
)

# Link optional libraries if available
if(HAS_SVT_AV1)
    target_link_libraries(handbrake-android SvtAv1Enc)
endif()

if(HAS_VORBIS)
    target_link_libraries(handbrake-android vorbis)
endif()

if(HAS_VORBISENC)
    target_link_libraries(handbrake-android vorbisenc)
endif()

if(HAS_OGG)
    target_link_libraries(handbrake-android ogg)
endif()

if(HAS_THEORA)
    target_link_libraries(handbrake-android theora)
endif()

if(HAS_THEORAENC)
    target_link_libraries(handbrake-android theoraenc)
endif()

if(HAS_THEORADEC)
    target_link_libraries(handbrake-android theoradec)
endif()

if(HAS_LAME)
    target_link_libraries(handbrake-android mp3lame)
endif()

if(HAS_OPUS)
    target_link_libraries(handbrake-android opus)
endif()

# Preprocessor definitions - Full HandBrake functionality
target_compile_definitions(handbrake-core PRIVATE
    __LIBHB__
    ANDROID
    USE_PTHREAD
    HB_VERSION_MAJOR=1
    HB_VERSION_MINOR=8
    HB_VERSION_POINT=0
    
    # Enable HandBrake features
    HB_PROJECT_FEATURE_X264=1
    HB_PROJECT_FEATURE_X265=1
    HB_PROJECT_FEATURE_THEORA=1
    HB_PROJECT_FEATURE_VORBIS=1
    HB_PROJECT_FEATURE_LAME=1
    HB_PROJECT_FEATURE_SVT_AV1=0
    HB_PROJECT_FEATURE_OPUS=1
    
    # Disable hardware acceleration features not available on Android
    HB_PROJECT_FEATURE_QSV=0
    HB_PROJECT_FEATURE_VCE=0
    HB_PROJECT_FEATURE_NVENC=0
    HB_PROJECT_FEATURE_NVDEC=0
    HB_PROJECT_FEATURE_VIDEOTOOLBOX=0
    HB_PROJECT_FEATURE_MF=0
    
    # FFmpeg integration
    USE_LIBAV_CHAPTER=1
    USE_HB_FF_EXTRADATA=1
)

target_compile_definitions(handbrake-android PRIVATE
    __LIBHB__
    ANDROID
)