#include "handbrake_bridge.h"
#include <handbrake/handbrake.h>  // Enable full HandBrake functionality
#include <handbrake/hb_json.h>    // Enable JSON API
#include <handbrake/preset.h>     // Enable preset functionality
#include <android/log.h>
#include <cstring>
#include <cstdlib>

#define LOG_TAG "HandBrake-Bridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Global log callback
static void (*g_log_callback)(const char* message) = nullptr;

// Custom log handler for HandBrake
static void hb_log_handler(const char* message) {
    if (g_log_callback) {
        g_log_callback(message);
    }
    LOGI("%s", message);
}

extern "C" {

void* handbrake_init(int verbose) {
    try {
        LOGI("HandBrake full init (verbose: %d)", verbose);
        
        // Initialize HandBrake global
        if (hb_global_init() < 0) {
            LOGE("Failed to initialize HandBrake global");
            return nullptr;
        }
        
        // Register log handler
        hb_register_logger(hb_log_handler);
        
        // Initialize HandBrake handle
        hb_handle_t* handle = hb_init(verbose);
        if (!handle) {
            LOGE("Failed to initialize HandBrake handle");
            return nullptr;
        }
        
        LOGI("HandBrake initialized successfully");
        return handle;
    } catch (...) {
        LOGE("Exception occurred during HandBrake initialization");
        return nullptr;
    }
}

void handbrake_close(void* handle) {
    if (handle) {
        try {
            hb_handle_t* hb = (hb_handle_t*)handle;
            hb_close(&hb);
            LOGI("HandBrake closed successfully");
        } catch (...) {
            LOGE("Exception occurred while closing HandBrake");
        }
    }
}

const char* handbrake_get_version(void* handle) {
    if (!handle) return "Unknown";
    
    try {
        hb_handle_t* hb = (hb_handle_t*)handle;
        return hb_get_version(hb);
    } catch (...) {
        LOGE("Exception occurred while getting version");
        return "Error";
    }
}

int handbrake_scan(void* handle, const char* input_path, int title_index) {
    if (!handle || !input_path) return 0;
    
    try {
        hb_handle_t* hb = (hb_handle_t*)handle;
        
        // Create path list
        hb_list_t* paths = hb_list_init();
        if (!paths) {
            LOGE("Failed to create path list");
            return 0;
        }
        
        char* path_copy = strdup(input_path);
        hb_list_add(paths, path_copy);
        
        // Start scan
        hb_scan(hb, paths, title_index, 
                10, 0, // preview_count, store_previews
                0, 0,  // min_duration, max_duration  
                16, 4, // crop_threshold_frames, crop_threshold_pixels
                nullptr, // exclude_extensions
                0, 0); // hw_decode, keep_duplicate_titles
        
        LOGI("Scan started for: %s", input_path);
        return 1;
    } catch (...) {
        LOGE("Exception occurred during scan");
        return 0;
    }
}

int handbrake_get_scan_progress(void* handle) {
    if (!handle) return -1;
    
    try {
        hb_handle_t* hb = (hb_handle_t*)handle;
        hb_state_t state;
        hb_get_state(hb, &state);
        
        if (state.state == HB_STATE_SCANNING) {
            return (int)(state.param.scanning.progress * 100);
        }
        
        return state.state == HB_STATE_SCANDONE ? 100 : 0;
    } catch (...) {
        LOGE("Exception occurred while getting scan progress");
        return -1;
    }
}

int handbrake_get_title_count(void* handle) {
    if (!handle) return 0;
    
    try {
        hb_handle_t* hb = (hb_handle_t*)handle;
        hb_list_t* titles = hb_get_titles(hb);
        return titles ? hb_list_count(titles) : 0;
    } catch (...) {
        LOGE("Exception occurred while getting title count");
        return 0;
    }
}

char* handbrake_get_title_info_json(void* handle, int title_index) {
    if (!handle) return nullptr;
    
    try {
        hb_handle_t* hb = (hb_handle_t*)handle;
        hb_title_set_t* title_set = hb_get_title_set(hb);
        
        if (!title_set || !title_set->list_title) {
            return nullptr;
        }
        
        hb_title_t* title = (hb_title_t*)hb_list_item(title_set->list_title, title_index);
        if (!title) {
            return nullptr;
        }
        
        // Convert title to JSON (you'll need to implement this based on HandBrake's JSON API)
        hb_dict_t* title_dict = hb_title_to_dict(hb, title_index);
        char* json = hb_value_get_json(title_dict);
        hb_value_free(&title_dict);
        
        return json; // Note: caller should free this
    } catch (...) {
        LOGE("Exception occurred while getting title info");
        return nullptr;
    }
}

int handbrake_start_encode(void* handle, const char* job_json) {
    if (!handle || !job_json) return 0;
    
    try {
        hb_handle_t* hb = (hb_handle_t*)handle;
        
        // Parse JSON job configuration
        hb_dict_t* job_dict = hb_value_json(job_json);
        if (!job_dict) {
            LOGE("Failed to parse job JSON");
            return 0;
        }
        
        // Add job to queue
        int result = hb_add_json(hb, job_json);
        hb_value_free(&job_dict);
        
        if (result != 0) {
            LOGE("Failed to add job to queue");
            return 0;
        }
        
        // Start encoding
        hb_start(hb);
        LOGI("Encoding started");
        return 1;
    } catch (...) {
        LOGE("Exception occurred while starting encode");
        return 0;
    }
}

int handbrake_stop_encode(void* handle) {
    if (!handle) return 0;
    
    try {
        hb_handle_t* hb = (hb_handle_t*)handle;
        hb_stop(hb);
        LOGI("Encoding stopped");
        return 1;
    } catch (...) {
        LOGE("Exception occurred while stopping encode");
        return 0;
    }
}

int handbrake_get_encode_progress(void* handle) {
    if (!handle) return -1;
    
    try {
        hb_handle_t* hb = (hb_handle_t*)handle;
        hb_state_t state;
        hb_get_state(hb, &state);
        
        if (state.state == HB_STATE_WORKING) {
            return (int)(state.param.working.progress * 100);
        }
        
        return state.state == HB_STATE_WORKDONE ? 100 : 0;
    } catch (...) {
        LOGE("Exception occurred while getting encode progress");
        return -1;
    }
}

char* handbrake_get_state_json(void* handle) {
    if (!handle) return nullptr;
    
    try {
        hb_handle_t* hb = (hb_handle_t*)handle;
        hb_state_t state;
        hb_get_state(hb, &state);
        
        // Convert state to JSON (implement based on your needs)
        hb_dict_t* state_dict = hb_dict_init();
        hb_dict_set_int(state_dict, "state", state.state);
        
        if (state.state == HB_STATE_SCANNING) {
            hb_dict_set_double(state_dict, "progress", state.param.scanning.progress);
        } else if (state.state == HB_STATE_WORKING) {
            hb_dict_set_double(state_dict, "progress", state.param.working.progress);
            hb_dict_set_double(state_dict, "rate_avg", state.param.working.rate_avg);
        }
        
        char* json = hb_value_get_json(state_dict);
        hb_value_free(&state_dict);
        
        return json; // Note: caller should free this
    } catch (...) {
        LOGE("Exception occurred while getting state");
        return nullptr;
    }
}

char* handbrake_get_presets_json(void* handle) {
    try {
        // Get built-in presets
        const char* presets = hb_presets_builtin_get_json();
        return (char*)presets;
    } catch (...) {
        LOGE("Exception occurred while getting presets");
        return nullptr;
    }
}

const char* handbrake_get_available_presets_json(void) {
    try {
        // Get built-in presets (same implementation as above)
        const char* presets = hb_presets_builtin_get_json();
        return presets;
    } catch (...) {
        LOGE("Exception occurred while getting available presets");
        return nullptr;
    }
}

const char* handbrake_apply_preset_to_title(const char* preset_name, const char* title_json) {
    if (!preset_name || !title_json) return nullptr;
    
    try {
        // Parse title JSON
        hb_dict_t* title_dict = hb_value_json(title_json);
        if (!title_dict) {
            LOGE("Failed to parse title JSON");
            return nullptr;
        }
        
        // For now, we'll create a dummy handle and title index
        // In a real implementation, you'd need access to the actual handle
        hb_handle_t* hb = nullptr; // This is a placeholder
        int title_index = 0;
        
        // We need to find the preset by name first
        const char* presets_json = hb_presets_builtin_get_json();
        hb_dict_t* presets_dict = hb_value_json(presets_json);
        // This is a simplified version - you'd need to search through the presets
        // to find the one matching preset_name
        
        // Apply preset to create job (using title_dict as preset for now)
        hb_dict_t* job_dict = hb_preset_job_init(hb, title_index, title_dict);
        hb_value_free(&title_dict);
        hb_value_free(&presets_dict);
        
        if (!job_dict) {
            LOGE("Failed to apply preset: %s", preset_name);
            return nullptr;
        }
        
        char* json = hb_value_get_json(job_dict);
        hb_value_free(&job_dict);
        
        return json; // Note: caller should free this
    } catch (...) {
        LOGE("Exception occurred while applying preset");
        return nullptr;
    }
}

void handbrake_set_log_callback(void (*callback)(const char* message)) {
    g_log_callback = callback;
}

} // extern "C"