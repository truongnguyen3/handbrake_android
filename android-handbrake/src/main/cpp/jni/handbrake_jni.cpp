#include <jni.h>
#include <string>
#include <android/log.h>
#include "handbrake_bridge.h"

#define LOG_TAG "HandBrake-JNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C" {

// Initialize HandBrake
JNIEXPORT jlong JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeInit(JNIEnv *env, jobject thiz, jint verbose) {
    LOGI("Initializing HandBrake with verbose level: %d", verbose);
    return (jlong) handbrake_init(verbose);
}

// Close HandBrake
JNIEXPORT void JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeClose(JNIEnv *env, jobject thiz, jlong handle) {
    LOGI("Closing HandBrake handle: %ld", handle);
    handbrake_close((void*)handle);
}

// Get version
JNIEXPORT jstring JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeGetVersion(JNIEnv *env, jobject thiz, jlong handle) {
    const char* version = handbrake_get_version((void*)handle);
    return env->NewStringUTF(version);
}

// Scan media file
JNIEXPORT jboolean JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeScan(JNIEnv *env, jobject thiz, 
                                                  jlong handle, jstring input_path, 
                                                  jint title_index) {
    const char* path = env->GetStringUTFChars(input_path, NULL);
    LOGI("Scanning file: %s", path);
    
    bool result = handbrake_scan((void*)handle, path, title_index);
    
    env->ReleaseStringUTFChars(input_path, path);
    return (jboolean)result;
}

// Get scan progress
JNIEXPORT jint JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeGetScanProgress(JNIEnv *env, jobject thiz, jlong handle) {
    return handbrake_get_scan_progress((void*)handle);
}

// Get title count
JNIEXPORT jint JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeGetTitleCount(JNIEnv *env, jobject thiz, jlong handle) {
    return handbrake_get_title_count((void*)handle);
}

// Start encoding
JNIEXPORT jboolean JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeStartEncode(JNIEnv *env, jobject thiz, 
                                                         jlong handle, jstring job_json) {
    const char* json = env->GetStringUTFChars(job_json, NULL);
    LOGI("Starting encode with job: %s", json);
    
    bool result = handbrake_start_encode((void*)handle, json);
    
    env->ReleaseStringUTFChars(job_json, json);
    return (jboolean)result;
}

// Stop encoding
JNIEXPORT void JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeStopEncode(JNIEnv *env, jobject thiz, jlong handle) {
    LOGI("Stopping encode");
    handbrake_stop_encode((void*)handle);
}

// Get encoding progress
JNIEXPORT jint JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeGetEncodeProgress(JNIEnv *env, jobject thiz, jlong handle) {
    return handbrake_get_encode_progress((void*)handle);
}

// Get state as JSON
JNIEXPORT jstring JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeGetState(JNIEnv *env, jobject thiz, jlong handle) {
    const char* state = handbrake_get_state_json((void*)handle);
    return env->NewStringUTF(state ? state : "{}");
}

// Get title info as JSON
JNIEXPORT jstring JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeGetTitleInfo(JNIEnv *env, jobject thiz, 
                                                          jlong handle, jint title_index) {
    const char* info = handbrake_get_title_info_json((void*)handle, title_index);
    return env->NewStringUTF(info ? info : "{}");
}

// Get available presets
JNIEXPORT jstring JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeGetPresets(JNIEnv *env, jobject thiz) {
    const char* presets = handbrake_get_available_presets_json();
    return env->NewStringUTF(presets ? presets : "[]");
}

// Apply preset
JNIEXPORT jstring JNICALL
Java_com_handbrake_core_HandBrakeCore_nativeApplyPreset(JNIEnv *env, jobject thiz, 
                                                         jstring preset_name, jstring title_json) {
    const char* preset = env->GetStringUTFChars(preset_name, NULL);
    const char* title = env->GetStringUTFChars(title_json, NULL);
    
    const char* job = handbrake_apply_preset_to_title(preset, title);
    jstring result = env->NewStringUTF(job ? job : "{}");
    
    env->ReleaseStringUTFChars(preset_name, preset);
    env->ReleaseStringUTFChars(title_json, title);
    
    return result;
}

} // extern "C"