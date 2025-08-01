#ifndef HANDBRAKE_BRIDGE_H
#define HANDBRAKE_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

// HandBrake Core wrapper functions for Android
// These functions provide a simplified C interface to HandBrake's core functionality

/**
 * Initialize HandBrake core
 * @param verbose - verbosity level for logging
 * @return handle to HandBrake instance or NULL on failure
 */
void* handbrake_init(int verbose);

/**
 * Close HandBrake instance and free resources
 * @param handle - HandBrake instance handle
 */
void handbrake_close(void* handle);

/**
 * Get HandBrake version string
 * @param handle - HandBrake instance handle
 * @return version string
 */
const char* handbrake_get_version(void* handle);

/**
 * Scan media file or directory
 * @param handle - HandBrake instance handle
 * @param input_path - path to input file or directory
 * @param title_index - title index to scan (0 for all)
 * @return true on success, false on failure
 */
int handbrake_scan(void* handle, const char* input_path, int title_index);

/**
 * Get scan progress percentage
 * @param handle - HandBrake instance handle
 * @return progress percentage (0-100)
 */
int handbrake_get_scan_progress(void* handle);

/**
 * Get number of titles found
 * @param handle - HandBrake instance handle
 * @return number of titles
 */
int handbrake_get_title_count(void* handle);

/**
 * Get title information as JSON
 * @param handle - HandBrake instance handle
 * @param title_index - title index
 * @return JSON string with title information
 */
char* handbrake_get_title_info_json(void* handle, int title_index);

/**
 * Start encoding with job configuration
 * @param handle - HandBrake instance handle
 * @param job_json - job configuration in JSON format
 * @return true on success, false on failure
 */
int handbrake_start_encode(void* handle, const char* job_json);

/**
 * Stop current encoding operation
 * @param handle - HandBrake instance handle
 */
int handbrake_stop_encode(void* handle);

/**
 * Get encoding progress percentage
 * @param handle - HandBrake instance handle
 * @return progress percentage (0-100)
 */
int handbrake_get_encode_progress(void* handle);

/**
 * Get current state as JSON
 * @param handle - HandBrake instance handle
 * @return JSON string with current state
 */
char* handbrake_get_state_json(void* handle);

/**
 * Get available presets as JSON (static version)
 * @return JSON array of available presets
 */
const char* handbrake_get_available_presets_json(void);

/**
 * Apply preset to create job configuration
 * @param preset_name - name of preset to apply
 * @param title_json - title information in JSON format
 * @return job configuration in JSON format
 */
const char* handbrake_apply_preset_to_title(const char* preset_name, const char* title_json);

/**
 * Set log callback function
 * @param callback - function to handle log messages
 */
void handbrake_set_log_callback(void (*callback)(const char* message));

/**
 * Additional functions for JNI compatibility
 */
int handbrake_scan(void* handle, const char* input_path, int title_index);
int handbrake_get_scan_progress(void* handle);
int handbrake_get_title_count(void* handle);
char* handbrake_get_state_json(void* handle);
char* handbrake_get_presets_json(void* handle);
int handbrake_apply_preset(void* handle, const char* preset_name);

#ifdef __cplusplus
}
#endif

#endif // HANDBRAKE_BRIDGE_H