#include "handbrake_bridge.h"
#include <android/log.h>
#include <cstring>
#include <cstdlib>

#define LOG_TAG "HandBrake-Bridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Global log callback
static void (*g_log_callback)(const char* message) = nullptr;

extern "C" {

void* handbrake_init(int verbose) {
    LOGI("HandBrake minimal init (verbose: %d)", verbose);
    // Return a dummy handle for minimal build
    return (void*)0x12345678;
}

void handbrake_close(void* handle) {
    if (handle) {
        LOGI("HandBrake minimal close");
        // Nothing to do in minimal build
    }
}

const char* handbrake_get_version(void* handle) {
    return "HandBrake 1.8.0 Android Minimal";
}

int handbrake_scan_title(void* handle, const char* input_path, int title_index) {
    if (!handle || !input_path) {
        LOGE("Invalid parameters for scan");
        return -1;
    }
    
    LOGI("Minimal scan: %s (title: %d)", input_path, title_index);
    // Simulate scan success
    return 0;
}

char* handbrake_get_title_info_json(void* handle, int title_index) {
    if (!handle) {
        return nullptr;
    }
    
    // Return minimal JSON
    const char* json = "{"
        "\"TitleList\": ["
        "{"
        "\"Index\": 1,"
        "\"Duration\": {"
        "\"Hours\": 0,"
        "\"Minutes\": 1,"
        "\"Seconds\": 30"
        "},"
        "\"VideoTracks\": ["
        "{"
        "\"Width\": 1920,"
        "\"Height\": 1080,"
        "\"FrameRate\": 30"
        "}"
        "],"
        "\"AudioTracks\": ["
        "{"
        "\"Language\": \"English\","
        "\"Channels\": 2"
        "}"
        "]"
        "}"
        "]"
        "}";
    
    char* result = (char*)malloc(strlen(json) + 1);
    if (result) {
        strcpy(result, json);
    }
    return result;
}

int handbrake_start_encode(void* handle, const char* job_json) {
    if (!handle || !job_json) {
        LOGE("Invalid parameters for encode");
        return -1;
    }
    
    LOGI("Minimal encode start (job length: %zu)", strlen(job_json));
    // Simulate encode start success
    return 0;
}

int handbrake_get_encode_progress(void* handle) {
    if (!handle) {
        return -1;
    }
    
    // Simulate encoding progress (always return 50% for demo)
    return 50;
}

int handbrake_stop_encode(void* handle) {
    if (!handle) {
        return -1;
    }
    
    LOGI("Minimal encode stop");
    return 0;
}

void handbrake_set_log_callback(void (*callback)(const char*)) {
    g_log_callback = callback;
    LOGI("Log callback set");
}

int handbrake_get_last_error_code(void* handle) {
    return 0; // No errors in minimal build
}

const char* handbrake_get_last_error_message(void* handle) {
    return "No error (minimal build)";
}

char* handbrake_get_preset_json(void* handle, const char* preset_name) {
    if (!preset_name) {
        return nullptr;
    }
    
    // Return minimal preset JSON
    const char* preset = "{"
        "\"PresetName\": \"Android Fast\","
        "\"VideoEncoder\": \"x264\","
        "\"VideoQuality\": 22.0,"
        "\"AudioList\": ["
        "{"
        "\"AudioEncoder\": \"aac\","
        "\"AudioBitrate\": 160"
        "}"
        "]"
        "}";
    
    char* result = (char*)malloc(strlen(preset) + 1);
    if (result) {
        strcpy(result, preset);
    }
    return result;
}

void handbrake_free_string(char* str) {
    if (str) {
        free(str);
    }
}

// Additional functions called by JNI layer
int handbrake_scan(void* handle, const char* input_path, int title_index) {
    return handbrake_scan_title(handle, input_path, title_index);
}

int handbrake_get_scan_progress(void* handle) {
    // Return scan complete (100%)
    return 100;
}

int handbrake_get_title_count(void* handle) {
    // Return 1 title for minimal demo
    return 1;
}

char* handbrake_get_state_json(void* handle) {
    const char* state = "{"
        "\"State\": \"Idle\","
        "\"Progress\": 0.0,"
        "\"Rate\": 0.0,"
        "\"RateAvg\": 0.0,"
        "\"Hours\": 0,"
        "\"Minutes\": 0,"
        "\"Seconds\": 0"
        "}";
    
    char* result = (char*)malloc(strlen(state) + 1);
    if (result) {
        strcpy(result, state);
    }
    return result;
}

char* handbrake_get_presets_json(void* handle) {
    const char* presets = "{"
        "\"PresetList\": ["
        "{"
        "\"PresetName\": \"Android Fast\","
        "\"Type\": 1,"
        "\"Default\": true,"
        "\"VideoEncoder\": \"x264\","
        "\"VideoQuality\": 22.0"
        "},"
        "{"
        "\"PresetName\": \"Android Normal\","
        "\"Type\": 1,"
        "\"Default\": false,"
        "\"VideoEncoder\": \"x264\","
        "\"VideoQuality\": 20.0"
        "}"
        "]"
        "}";
    
    char* result = (char*)malloc(strlen(presets) + 1);
    if (result) {
        strcpy(result, presets);
    }
    return result;
}

int handbrake_apply_preset(void* handle, const char* preset_name) {
    if (!handle || !preset_name) {
        return -1;
    }
    
    LOGI("Applied preset: %s", preset_name);
    return 0;
}

const char* handbrake_apply_preset_to_title(const char* preset_name, const char* title_json) {
    if (!preset_name || !title_json) {
        return nullptr;
    }
    
    // Return a minimal job configuration JSON
    const char* job = "{"
        "\"Job\": {"
        "\"PresetName\": \"Android Fast\","
        "\"VideoEncoder\": \"x264\","
        "\"VideoQuality\": 22.0,"
        "\"AudioList\": ["
        "{"
        "\"AudioEncoder\": \"aac\","
        "\"AudioBitrate\": 160"
        "}"
        "]"
        "}"
        "}";
    
    return job;
}

const char* handbrake_get_available_presets_json(void) {
    return "{"
        "\"PresetList\": ["
        "{"
        "\"PresetName\": \"Android Fast\","
        "\"Type\": 1,"
        "\"Default\": true"
        "}"
        "]"
        "}";
}

} // extern "C"