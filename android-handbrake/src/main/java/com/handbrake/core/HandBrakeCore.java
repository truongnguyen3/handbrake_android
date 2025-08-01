package com.handbrake.core;

import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

/**
 * HandBrake Core Android wrapper
 * Provides access to HandBrake's video transcoding functionality on Android
 */
public class HandBrakeCore {
    private static final String TAG = "HandBrakeCore";
    
    // Load native library
    static {
        try {
            System.loadLibrary("handbrake-android");
            Log.i(TAG, "HandBrake native library loaded successfully");
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "Failed to load HandBrake native library", e);
            throw new RuntimeException("Failed to load HandBrake native library", e);
        }
    }
    
    private long nativeHandle = 0;
    private HandBrakeListener listener;
    
    /**
     * Interface for HandBrake callbacks
     */
    public interface HandBrakeListener {
        /**
         * Called when scan progress changes
         * @param progress Progress percentage (0-100)
         */
        void onScanProgress(int progress);
        
        /**
         * Called when scan is completed
         * @param titleCount Number of titles found
         */
        void onScanCompleted(int titleCount);
        
        /**
         * Called when encoding progress changes
         * @param progress Progress percentage (0-100)
         * @param currentFps Current encoding FPS
         * @param avgFps Average encoding FPS
         */
        void onEncodeProgress(int progress, double currentFps, double avgFps);
        
        /**
         * Called when encoding is completed
         * @param success True if encoding completed successfully
         */
        void onEncodeCompleted(boolean success);
        
        /**
         * Called when an error occurs
         * @param error Error message
         */
        void onError(String error);
        
        /**
         * Called with log messages
         * @param message Log message
         */
        void onLogMessage(String message);
    }
    
    /**
     * Initialize HandBrake core
     * @param verbose Verbosity level (0-3)
     * @return True if initialization successful
     */
    public boolean initialize(int verbose) {
        if (nativeHandle != 0) {
            Log.w(TAG, "HandBrake already initialized");
            return true;
        }
        
        nativeHandle = nativeInit(verbose);
        if (nativeHandle == 0) {
            Log.e(TAG, "Failed to initialize HandBrake");
            return false;
        }
        
        Log.i(TAG, "HandBrake initialized successfully");
        return true;
    }
    
    /**
     * Close HandBrake and free resources
     */
    public void close() {
        if (nativeHandle != 0) {
            nativeClose(nativeHandle);
            nativeHandle = 0;
            Log.i(TAG, "HandBrake closed");
        }
    }
    
    /**
     * Get HandBrake version
     * @return Version string
     */
    @NonNull
    public String getVersion() {
        if (nativeHandle == 0) {
            return "Not initialized";
        }
        return nativeGetVersion(nativeHandle);
    }
    
    /**
     * Scan media file
     * @param inputPath Path to input file
     * @param titleIndex Title index to scan (0 for all)
     * @return True if scan started successfully
     */
    public boolean scan(@NonNull String inputPath, int titleIndex) {
        if (nativeHandle == 0) {
            Log.e(TAG, "HandBrake not initialized");
            return false;
        }
        
        Log.i(TAG, "Starting scan: " + inputPath);
        return nativeScan(nativeHandle, inputPath, titleIndex);
    }
    
    /**
     * Get scan progress
     * @return Progress percentage (0-100), -1 if error
     */
    public int getScanProgress() {
        if (nativeHandle == 0) return -1;
        return nativeGetScanProgress(nativeHandle);
    }
    
    /**
     * Get number of titles found
     * @return Number of titles
     */
    public int getTitleCount() {
        if (nativeHandle == 0) return 0;
        return nativeGetTitleCount(nativeHandle);
    }
    
    /**
     * Get title information as JSON
     * @param titleIndex Title index
     * @return JSON string with title information
     */
    @Nullable
    public String getTitleInfo(int titleIndex) {
        if (nativeHandle == 0) return null;
        return nativeGetTitleInfo(nativeHandle, titleIndex);
    }
    
    /**
     * Start encoding with job configuration
     * @param jobJson Job configuration in JSON format
     * @return True if encoding started successfully
     */
    public boolean startEncode(@NonNull String jobJson) {
        if (nativeHandle == 0) {
            Log.e(TAG, "HandBrake not initialized");
            return false;
        }
        
        Log.i(TAG, "Starting encode");
        return nativeStartEncode(nativeHandle, jobJson);
    }
    
    /**
     * Stop current encoding
     */
    public void stopEncode() {
        if (nativeHandle != 0) {
            nativeStopEncode(nativeHandle);
            Log.i(TAG, "Encode stopped");
        }
    }
    
    /**
     * Get encoding progress
     * @return Progress percentage (0-100), -1 if error
     */
    public int getEncodeProgress() {
        if (nativeHandle == 0) return -1;
        return nativeGetEncodeProgress(nativeHandle);
    }
    
    /**
     * Get current state as JSON
     * @return JSON string with current state
     */
    @Nullable
    public String getState() {
        if (nativeHandle == 0) return null;
        return nativeGetState(nativeHandle);
    }
    
    /**
     * Get available presets as JSON
     * @return JSON array of available presets
     */
    @NonNull
    public static String getPresets() {
        return nativeGetPresets();
    }
    
    /**
     * Apply preset to create job configuration
     * @param presetName Name of preset to apply
     * @param titleJson Title information in JSON format
     * @return Job configuration in JSON format
     */
    @Nullable
    public static String applyPreset(@NonNull String presetName, @NonNull String titleJson) {
        return nativeApplyPreset(presetName, titleJson);
    }
    
    /**
     * Set listener for callbacks
     * @param listener HandBrake listener
     */
    public void setListener(@Nullable HandBrakeListener listener) {
        this.listener = listener;
    }
    
    /**
     * Check if HandBrake is initialized
     * @return True if initialized
     */
    public boolean isInitialized() {
        return nativeHandle != 0;
    }
    
    @Override
    protected void finalize() throws Throwable {
        super.finalize();
        close();
    }
    
    // Native method declarations
    private native long nativeInit(int verbose);
    private native void nativeClose(long handle);
    private native String nativeGetVersion(long handle);
    private native boolean nativeScan(long handle, String inputPath, int titleIndex);
    private native int nativeGetScanProgress(long handle);
    private native int nativeGetTitleCount(long handle);
    private native String nativeGetTitleInfo(long handle, int titleIndex);
    private native boolean nativeStartEncode(long handle, String jobJson);
    private native void nativeStopEncode(long handle);
    private native int nativeGetEncodeProgress(long handle);
    private native String nativeGetState(long handle);
    private static native String nativeGetPresets();
    private static native String nativeApplyPreset(String presetName, String titleJson);
}