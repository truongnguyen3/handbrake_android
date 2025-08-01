package com.handbrake.core;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * HandBrake job configuration builder
 * Provides a convenient way to create encoding jobs
 */
public class HandBrakeJob {
    private JSONObject jobConfig;
    
    public HandBrakeJob() {
        jobConfig = new JSONObject();
        try {
            // Set default values
            jobConfig.put("SequenceID", 0);
            jobConfig.put("Audio", new JSONObject());
            jobConfig.put("Video", new JSONObject());
            jobConfig.put("Subtitle", new JSONObject());
            jobConfig.put("Filter", new JSONObject());
            jobConfig.put("Metadata", new JSONObject());
        } catch (JSONException e) {
            throw new RuntimeException("Failed to initialize job config", e);
        }
    }
    
    /**
     * Set input source
     * @param source Input file path or title index
     * @return This job builder
     */
    public HandBrakeJob setSource(@NonNull String source) {
        try {
            jobConfig.put("Source", source);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set source", e);
        }
        return this;
    }
    
    /**
     * Set output destination
     * @param destination Output file path
     * @return This job builder
     */
    public HandBrakeJob setDestination(@NonNull String destination) {
        try {
            jobConfig.put("Destination", destination);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set destination", e);
        }
        return this;
    }
    
    /**
     * Set title index
     * @param titleIndex Title index to encode
     * @return This job builder
     */
    public HandBrakeJob setTitle(int titleIndex) {
        try {
            jobConfig.put("Title", titleIndex);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set title", e);
        }
        return this;
    }
    
    /**
     * Set output format
     * @param format Output format ("av_mp4", "av_mkv", "av_webm")
     * @return This job builder
     */
    public HandBrakeJob setFormat(@NonNull String format) {
        try {
            jobConfig.put("Format", format);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set format", e);
        }
        return this;
    }
    
    /**
     * Set video encoder
     * @param encoder Video encoder ("x264", "x265", "vt_h264", etc.)
     * @return This job builder
     */
    public HandBrakeJob setVideoEncoder(@NonNull String encoder) {
        try {
            JSONObject video = jobConfig.getJSONObject("Video");
            video.put("Encoder", encoder);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set video encoder", e);
        }
        return this;
    }
    
    /**
     * Set video quality (CRF mode)
     * @param quality Quality value (0-51 for x264/x265, lower is better)
     * @return This job builder
     */
    public HandBrakeJob setVideoQuality(double quality) {
        try {
            JSONObject video = jobConfig.getJSONObject("Video");
            video.put("Quality", quality);
            video.put("QualityType", 2); // CRF mode
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set video quality", e);
        }
        return this;
    }
    
    /**
     * Set video bitrate (ABR mode)
     * @param bitrate Bitrate in kbps
     * @return This job builder
     */
    public HandBrakeJob setVideoBitrate(int bitrate) {
        try {
            JSONObject video = jobConfig.getJSONObject("Video");
            video.put("Bitrate", bitrate);
            video.put("QualityType", 1); // ABR mode
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set video bitrate", e);
        }
        return this;
    }
    
    /**
     * Set video resolution
     * @param width Video width
     * @param height Video height
     * @return This job builder
     */
    public HandBrakeJob setVideoResolution(int width, int height) {
        try {
            JSONObject video = jobConfig.getJSONObject("Video");
            video.put("Width", width);
            video.put("Height", height);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set video resolution", e);
        }
        return this;
    }
    
    /**
     * Set video framerate
     * @param framerate Framerate (e.g., 23.976, 25, 29.97, 30)
     * @return This job builder
     */
    public HandBrakeJob setVideoFramerate(double framerate) {
        try {
            JSONObject video = jobConfig.getJSONObject("Video");
            video.put("Framerate", framerate);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set video framerate", e);
        }
        return this;
    }
    
    /**
     * Set audio encoder for track
     * @param track Audio track index (0-based)
     * @param encoder Audio encoder ("av_aac", "mp3", "ac3", etc.)
     * @return This job builder
     */
    public HandBrakeJob setAudioEncoder(int track, @NonNull String encoder) {
        try {
            JSONObject audio = jobConfig.getJSONObject("Audio");
            // Audio configuration is more complex, this is simplified
            audio.put("Track" + track + "Encoder", encoder);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set audio encoder", e);
        }
        return this;
    }
    
    /**
     * Set chapter range
     * @param startChapter Start chapter (1-based)
     * @param endChapter End chapter (1-based)
     * @return This job builder
     */
    public HandBrakeJob setChapterRange(int startChapter, int endChapter) {
        try {
            JSONObject range = new JSONObject();
            range.put("Type", "chapter");
            range.put("Start", startChapter);
            range.put("End", endChapter);
            jobConfig.put("Range", range);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set chapter range", e);
        }
        return this;
    }
    
    /**
     * Set time range
     * @param startSeconds Start time in seconds
     * @param endSeconds End time in seconds
     * @return This job builder
     */
    public HandBrakeJob setTimeRange(double startSeconds, double endSeconds) {
        try {
            JSONObject range = new JSONObject();
            range.put("Type", "time");
            range.put("Start", startSeconds);
            range.put("End", endSeconds);
            jobConfig.put("Range", range);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set time range", e);
        }
        return this;
    }
    
    /**
     * Enable/disable optimization for web streaming
     * @param optimize True to optimize for web
     * @return This job builder
     */
    public HandBrakeJob setOptimizeForWeb(boolean optimize) {
        try {
            jobConfig.put("Mp4HttpOptimize", optimize);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set web optimization", e);
        }
        return this;
    }
    
    /**
     * Add custom parameter
     * @param key Parameter key
     * @param value Parameter value
     * @return This job builder
     */
    public HandBrakeJob setParameter(@NonNull String key, @Nullable Object value) {
        try {
            jobConfig.put(key, value);
        } catch (JSONException e) {
            throw new RuntimeException("Failed to set parameter", e);
        }
        return this;
    }
    
    /**
     * Build the job configuration as JSON string
     * @return JSON string representation of the job
     */
    @NonNull
    public String toJson() {
        return jobConfig.toString();
    }
    
    /**
     * Create job from preset and title
     * @param presetName Preset name
     * @param titleJson Title information JSON
     * @return HandBrakeJob instance or null if failed
     */
    @Nullable
    public static HandBrakeJob fromPreset(@NonNull String presetName, @NonNull String titleJson) {
        String jobJson = HandBrakeCore.applyPreset(presetName, titleJson);
        if (jobJson == null) {
            return null;
        }
        
        try {
            HandBrakeJob job = new HandBrakeJob();
            job.jobConfig = new JSONObject(jobJson);
            return job;
        } catch (JSONException e) {
            return null;
        }
    }
    
    /**
     * Create job from JSON string
     * @param json JSON string
     * @return HandBrakeJob instance or null if failed
     */
    @Nullable
    public static HandBrakeJob fromJson(@NonNull String json) {
        try {
            HandBrakeJob job = new HandBrakeJob();
            job.jobConfig = new JSONObject(json);
            return job;
        } catch (JSONException e) {
            return null;
        }
    }
}