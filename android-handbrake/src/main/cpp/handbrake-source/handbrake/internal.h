/* internal.h

   Copyright (c) 2003-2025 HandBrake Team
   This file is part of the HandBrake source code
   Homepage: <http://handbrake.fr/>.
   It may be used under the terms of the GNU General Public License v2.
   For full terms see the file COPYING file or visit http://www.gnu.org/licenses/gpl-2.0.html
 */

#ifndef HANDBRAKE_INTERNAL_H
#define HANDBRAKE_INTERNAL_H

#include "libavutil/imgutils.h"
#include "libavutil/pixdesc.h"
#include "libavutil/frame.h"
#include "handbrake/project.h"

/***********************************************************************
 * common.c
 **********************************************************************/
void hb_log( char * log, ... ) HB_WPRINTF(1,2);
extern int global_verbosity_level; // Global variable for hb_deep_log
typedef enum hb_debug_level_s
{
    HB_SUPPORT_LOG      = 1, // helpful in tech support
    HB_HOUSEKEEPING_LOG = 2, // stuff we hate scrolling through
    HB_GRANULAR_LOG     = 3  // sample-by-sample
} hb_debug_level_t;
void hb_valog( hb_debug_level_t level, const char * prefix, const char * log, va_list args) HB_WPRINTF(3,0);
void hb_deep_log( hb_debug_level_t level, char * log, ... ) HB_WPRINTF(2,3);
void hb_error( char * fmt, ...) HB_WPRINTF(1,2);
void hb_hexdump( hb_debug_level_t level, const char * label, const uint8_t * data, int len );

int  hb_list_bytes( hb_list_t * );
void hb_list_seebytes( hb_list_t * l, uint8_t * dst, int size );
void hb_list_getbytes( hb_list_t * l, uint8_t * dst, int size,
                       uint64_t * pts, uint64_t * pos );
void hb_list_empty( hb_list_t ** );

hb_title_t * hb_title_init( char * dvd, int index );
void         hb_title_close( hb_title_t ** );

/***********************************************************************
 * hb.c
 **********************************************************************/
int  hb_get_pid( hb_handle_t * );
void hb_set_state( hb_handle_t *, hb_state_t * );
void hb_set_work_error( hb_handle_t * h, hb_error_code err );
void hb_job_setup_passes(hb_handle_t *h, hb_job_t *job, hb_list_t *list_pass);

/***********************************************************************
 * fifo.c
 **********************************************************************/

/*
 * Holds a packet of data that is moving through the transcoding process.
 *
 * May have metadata associated with it via extra fields
 * that are conditionally used depending on the type of packet.
 */
typedef struct hb_buffer_s hb_buffer_t;

struct hb_buffer_settings_s
{
    enum { OTHER_BUF, AUDIO_BUF, VIDEO_BUF, SUBTITLE_BUF, FRAME_BUF } type;

    int           id;           // ID of the track that the packet comes from
    int64_t       start;        // start time of frame
    double        duration;     // Actual duration, may be fractional ticks
    int64_t       stop;         // stop time of frame
    int64_t       renderOffset; // DTS used by b-frame offsets in muxmp4
    int64_t       pcr;
    int           scr_sequence; // The SCR sequence that this buffer's
                                // timestamps are referenced to
    int           split;
    uint8_t       discontinuity;
    int           new_chap;     // Video packets: if non-zero, is the index of the chapter whose boundary was crossed

#define HB_FRAME_IDR      0x01
#define HB_FRAME_I        0x02
#define HB_FRAME_AUDIO    0x04
#define HB_FRAME_SUBTITLE 0x08
#define HB_FRAME_P        0x10
#define HB_FRAME_B        0x20
#define HB_FRAME_BREF     0x40
#define HB_FRAME_MASK_KEY 0x0F
#define HB_FRAME_MASK_REF 0xF0
    uint8_t       frametype;

// Picture flags used by filters
#ifndef PIC_FLAG_TOP_FIELD_FIRST
#define PIC_FLAG_TOP_FIELD_FIRST    0x0008
#endif
#ifndef PIC_FLAG_PROGRESSIVE_FRAME
#define PIC_FLAG_PROGRESSIVE_FRAME  0x0010
#endif
#ifndef PIC_FLAG_REPEAT_FIRST_FIELD
#define PIC_FLAG_REPEAT_FIRST_FIELD 0x0100
#endif
#define PIC_FLAG_REPEAT_FRAME       0x0200
#define HB_BUF_FLAG_EOF             0x0400
#define HB_BUF_FLAG_EOS             0x0800
#define HB_FLAG_FRAMETYPE_KEY       0x1000
#define HB_FLAG_FRAMETYPE_REF       0x2000
#define HB_FLAG_DISCARD             0x4000
    uint16_t      flags;

#define HB_COMB_NONE  0
#define HB_COMB_LIGHT 1
#define HB_COMB_HEAVY 2
    uint8_t       combed;
};

struct hb_image_format_s
{
    int           x;
    int           y;
    int           width;
    int           height;
    int           fmt;
    int           color_prim;
    int           color_transfer;
    int           color_matrix;
    int           color_range;
    int           chroma_location;
    int           max_plane;
    int           window_width;
    int           window_height;
};

struct hb_buffer_s
{
    int           size;     // size of this packet
    int           alloc;    // used internally by the packet allocator (hb_buffer_init)
    uint8_t *     data;     // packet data
    int           offset;   // used internally by packet lists (hb_list_t)

    hb_buffer_settings_t s;
    hb_image_format_t f;

    struct buffer_plane
    {
        uint8_t     * data;
        int           stride;
        int           width;
        int           height;
        int           size;
    } plane[4]; // 3 Color components + alpha

    void  *storage;
    enum  { STANDARD, AVFRAME, COREMEDIA } storage_type;

    // libav may attach AV_PKT_DATA_PALETTE side data to some AVPackets
    // Store this data here when read and pass to decoder.
    hb_buffer_t * palette;

    void **side_data;
    int    nb_side_data;

    // Packets in a list:
    //   the next packet in the list
    hb_buffer_t * next;
};

void hb_buffer_pool_init( void );
void hb_buffer_pool_free( void );

hb_buffer_t * hb_buffer_wrapper_init();
hb_buffer_t * hb_buffer_init( int size );
hb_buffer_t * hb_buffer_eof_init( void );
hb_buffer_t * hb_frame_buffer_init( int pix_fmt, int w, int h);
void          hb_frame_buffer_blank_stride(hb_buffer_t * buf);
void          hb_frame_buffer_mirror_stride(hb_buffer_t * buf);
void          hb_buffer_init_planes( hb_buffer_t * b );
void          hb_buffer_realloc( hb_buffer_t *, int size );
void          hb_video_buffer_realloc( hb_buffer_t * b, int w, int h );
void          hb_buffer_reduce( hb_buffer_t * b, int size );
void          hb_buffer_close( hb_buffer_t ** );
hb_buffer_t * hb_buffer_dup( const hb_buffer_t * src );
hb_buffer_t * hb_buffer_shallow_dup( const hb_buffer_t *src );
int           hb_buffer_copy( hb_buffer_t * dst, const hb_buffer_t * src );
void          hb_buffer_swap_copy( hb_buffer_t *src, hb_buffer_t *dst );
hb_image_t  * hb_image_init(int pix_fmt, int width, int height);
hb_image_t  * hb_buffer_to_image(hb_buffer_t *buf);
int           hb_picture_fill(uint8_t *data[], int stride[], hb_buffer_t *b);
int           hb_picture_crop(uint8_t *data[], int stride[], hb_buffer_t *b,
                              int top, int left);

AVFrameSideData *hb_buffer_new_side_data_from_buf(hb_buffer_t *buf,
                                                  enum AVFrameSideDataType type,
                                                  AVBufferRef *side_data_buf);
void          hb_buffer_remove_side_data(hb_buffer_t *buf, enum AVFrameSideDataType type);
void          hb_buffer_wipe_side_data(hb_buffer_t *buf);
void          hb_buffer_copy_side_data(hb_buffer_t *dst, const hb_buffer_t *src);

void          hb_buffer_copy_props(hb_buffer_t *dst, const hb_buffer_t *src);

int           hb_buffer_is_writable(const hb_buffer_t *buf);

hb_fifo_t   * hb_fifo_init( int capacity, int thresh );
void          hb_fifo_register_full_cond( hb_fifo_t * f, hb_cond_t * c );
int           hb_fifo_size( hb_fifo_t * );
int           hb_fifo_size_bytes( hb_fifo_t * );
int           hb_fifo_is_full( hb_fifo_t * );
float         hb_fifo_percent_full( hb_fifo_t * f );
hb_buffer_t * hb_fifo_get( hb_fifo_t * );
hb_buffer_t * hb_fifo_get_wait( hb_fifo_t * );
hb_buffer_t * hb_fifo_see( hb_fifo_t * );
hb_buffer_t * hb_fifo_see_wait( hb_fifo_t * );
hb_buffer_t * hb_fifo_see2( hb_fifo_t * );
void          hb_fifo_push( hb_fifo_t *, hb_buffer_t * );
void          hb_fifo_push_wait( hb_fifo_t *, hb_buffer_t * );
int           hb_fifo_full_wait( hb_fifo_t * f );
void          hb_fifo_push_head( hb_fifo_t *, hb_buffer_t * );
void          hb_fifo_close( hb_fifo_t ** );
void          hb_fifo_flush( hb_fifo_t * f );

static inline int hb_image_stride( int pix_fmt, int width, int plane )
{
    int linesize = av_image_get_linesize( (enum AVPixelFormat)pix_fmt, width, plane );

    // Make buffer SIMD friendly.
    // Zscale requires stride aligned to 64 bytes
    linesize = MULTIPLE_MOD_UP(linesize, 64);
    return linesize;
}

static inline int hb_image_width(int pix_fmt, int width, int plane)
{
    const AVPixFmtDescriptor *desc = av_pix_fmt_desc_get((enum AVPixelFormat)pix_fmt);

    if (desc != NULL && (plane == 1 || plane == 2))
    {
        // The wacky arithmetic assures rounding up.
        width = -((-width) >> desc->log2_chroma_w);
    }

    return width;
}

static inline int hb_image_height(int pix_fmt, int height, int plane)
{
    const AVPixFmtDescriptor *desc = av_pix_fmt_desc_get((enum AVPixelFormat)pix_fmt);

    if (desc != NULL && (plane == 1 || plane == 2))
    {
        // The wacky arithmetic assures rounding up.
        height = -((-height) >> desc->log2_chroma_h);
    }

    return height;
}

static inline void hb_image_copy_plane(uint8_t *dst, const uint8_t *src,
                                       const int stride_dst, const int stride_src, const int height)
{
    if (src != dst)
    {
        if (stride_src == stride_dst)
        {
            memcpy(dst, src, stride_dst * height);
        }
        else
        {
            const int size = stride_src < stride_dst ? ABS(stride_src) : stride_dst;
            for (int yy = 0; yy < height; yy++)
            {
                memcpy(dst, src, size);
                dst += stride_dst;
                src += stride_src;
            }
        }
    }
}

/***********************************************************************
 * Threads: scan.c, work.c, reader.c, muxcommon.c
 **********************************************************************/
hb_thread_t * hb_scan_init( hb_handle_t *, volatile int * die,
                            hb_list_t * paths, int title_index,
                            hb_title_set_t * title_set, int preview_count,
                            int store_previews, uint64_t min_duration, uint64_t max_duration,
                            int crop_auto_switch_threshold, int crop_median_threshold,
                            hb_list_t * exclude_extensions, int hw_decode, int keep_duplicate_titles);
hb_thread_t * hb_work_init( hb_list_t * jobs,
                            volatile int * die, hb_error_code * error, hb_job_t ** job );
void ReadLoop( void * _w );
void hb_work_loop( void * );
hb_work_object_t * hb_muxer_init( hb_job_t * );
hb_work_object_t * hb_get_work( hb_handle_t *, int );
hb_work_object_t * hb_audio_decoder( hb_handle_t *, int );
hb_work_object_t * hb_audio_encoder( hb_handle_t *, int );
hb_work_object_t * hb_video_decoder( hb_handle_t *, int, int, void *, hb_hwaccel_t *hw_accel);
hb_work_object_t * hb_video_encoder( hb_handle_t *, int );

/***********************************************************************
 * sync.c
 **********************************************************************/
hb_work_object_t * hb_sync_init( hb_job_t * job );

/***********************************************************************
 * mpegdemux.c
 **********************************************************************/
typedef struct {
    int64_t last_scr;       /* unadjusted SCR from most recent pack */
    int64_t scr_delta;
    int64_t last_pts;       /* last pts we saw */
    int     scr_changes;    /* number of SCR discontinuities */
    int     new_chap;
} hb_psdemux_t;

typedef void (*hb_muxer_t)(hb_buffer_t *, hb_buffer_list_t *, hb_psdemux_t*);

void hb_demux_ps(hb_buffer_t * ps_buf, hb_buffer_list_t * es_list, hb_psdemux_t *);
void hb_demux_ts(hb_buffer_t * ps_buf, hb_buffer_list_t * es_list, hb_psdemux_t *);
void hb_demux_null(hb_buffer_t * ps_buf, hb_buffer_list_t * es_list, hb_psdemux_t *);

extern const hb_muxer_t hb_demux[];

/***********************************************************************
 * batch.c
 **********************************************************************/
typedef struct hb_batch_s hb_batch_t;

hb_batch_t  * hb_batch_init( hb_handle_t *h, char * path, hb_list_t * exclude_extensions );
void          hb_batch_close( hb_batch_t ** _d );
int           hb_batch_title_count( hb_batch_t * d );
hb_title_t  * hb_batch_title_scan( hb_batch_t * d, int t );
hb_title_t  * hb_batch_title_scan_single( hb_handle_t * h, char * filename, int t );
int           hb_is_valid_batch_path( const char * filename );

/***********************************************************************
 * dvd.c
 **********************************************************************/
typedef struct hb_bd_s hb_bd_t;
typedef union  hb_dvd_s hb_dvd_t;
typedef struct hb_stream_s hb_stream_t;

hb_dvd_t *   hb_dvd_init( hb_handle_t * h, const char * path );
int          hb_dvd_title_count( hb_dvd_t * );
hb_title_t * hb_dvd_title_scan( hb_dvd_t *, int title, uint64_t min_duration, uint64_t max_duration );
int          hb_dvd_start( hb_dvd_t *, hb_title_t *title, int chapter );
void         hb_dvd_stop( hb_dvd_t * );
int          hb_dvd_seek( hb_dvd_t *, float );
hb_buffer_t * hb_dvd_read( hb_dvd_t * );
int          hb_dvd_chapter( hb_dvd_t * );
int          hb_dvd_is_break( hb_dvd_t * d );
void         hb_dvd_close( hb_dvd_t ** );
int          hb_dvd_angle_count( hb_dvd_t * d );
void         hb_dvd_set_angle( hb_dvd_t * d, int angle );
int          hb_dvd_main_feature( hb_dvd_t * d, hb_list_t * list_title );

hb_bd_t     * hb_bd_init( hb_handle_t *h, const char * path, int keep_duplicate_titles );
int           hb_bd_title_count( hb_bd_t * d );
hb_title_t  * hb_bd_title_scan( hb_bd_t * d, int t, uint64_t min_duration, uint64_t max_duration );
int           hb_bd_start( hb_bd_t * d, hb_title_t *title );
void          hb_bd_stop( hb_bd_t * d );
int           hb_bd_seek( hb_bd_t * d, float f );
int           hb_bd_seek_pts( hb_bd_t * d, uint64_t pts );
int           hb_bd_seek_chapter( hb_bd_t * d, int chapter );
hb_buffer_t * hb_bd_read( hb_bd_t * d );
int           hb_bd_chapter( hb_bd_t * d );
void          hb_bd_close( hb_bd_t ** _d );
void          hb_bd_set_angle( hb_bd_t * d, int angle );
int           hb_bd_main_feature( hb_bd_t * d, hb_list_t * list_title );

hb_stream_t * hb_bd_stream_open( hb_handle_t *h, hb_title_t *title );
void hb_ts_stream_reset(hb_stream_t *stream);
hb_stream_t * hb_stream_open(hb_handle_t *h, const char * path,
                             hb_title_t *title, int scan);
void		 hb_stream_close( hb_stream_t ** );
hb_title_t * hb_stream_title_scan( hb_stream_t *, hb_title_t *);
hb_buffer_t * hb_stream_read( hb_stream_t * );
int          hb_stream_seek( hb_stream_t *, float );
int          hb_stream_seek_ts( hb_stream_t * stream, int64_t ts );
int          hb_stream_seek_chapter( hb_stream_t *, int );
int          hb_stream_chapter( hb_stream_t * );

hb_buffer_t * hb_ts_decode_pkt( hb_stream_t *stream, const uint8_t * pkt,
                                int chapter, int discontinuity );
void hb_stream_set_need_keyframe( hb_stream_t *stream, int need_keyframe );


#define STR4_TO_UINT32(p) \
    ((((const uint8_t*)(p))[0] << 24) | \
     (((const uint8_t*)(p))[1] << 16) | \
     (((const uint8_t*)(p))[2] <<  8) | \
      ((const uint8_t*)(p))[3])

/***********************************************************************
 * Work objects
 **********************************************************************/

#define HB_CONFIG_MAX_SIZE (2*8192)

struct hb_data_s
{
    uint8_t *bytes;
    size_t   size;
};

hb_data_t * hb_data_init(size_t size);
void        hb_data_close(hb_data_t **);
hb_data_t * hb_data_dup(const hb_data_t *src);

enum
{
    WORK_NONE = 0,
    WORK_PASS,
    WORK_SYNC_VIDEO,
    WORK_SYNC_AUDIO,
    WORK_SYNC_SUBTITLE,
    WORK_DECVOBSUB,
    WORK_DECSRTSUB,
    WORK_DECTX3GSUB,
    WORK_ENCTX3GSUB,
    WORK_DECSSASUB,
    WORK_RENDER,
    WORK_ENCAVCODEC,
    WORK_ENCVT,
    WORK_ENCX264,
    WORK_ENCX265,
    WORK_ENCSVTAV1,
    WORK_ENCTHEORA,
    WORK_DECAVCODEC,
    WORK_DECAVCODECV,
    WORK_DECLPCM,
    WORK_ENCLAME,
    WORK_ENCVORBIS,
    WORK_ENC_CA_AAC,
    WORK_ENC_CA_HAAC,
    WORK_ENCAVCODEC_AUDIO,
    WORK_MUX,
    WORK_READER,
    WORK_DECAVSUB,
    WORK_ENCAVSUB
};

extern hb_filter_object_t hb_filter_detelecine;
extern hb_filter_object_t hb_filter_comb_detect;
extern hb_filter_object_t hb_filter_decomb;
extern hb_filter_object_t hb_filter_yadif;
extern hb_filter_object_t hb_filter_bwdif;
extern hb_filter_object_t hb_filter_vfr;
extern hb_filter_object_t hb_filter_deblock;
extern hb_filter_object_t hb_filter_denoise;
extern hb_filter_object_t hb_filter_nlmeans;
extern hb_filter_object_t hb_filter_chroma_smooth;
extern hb_filter_object_t hb_filter_render_sub;
extern hb_filter_object_t hb_filter_rpu;
extern hb_filter_object_t hb_filter_crop_scale;
extern hb_filter_object_t hb_filter_rotate;
extern hb_filter_object_t hb_filter_grayscale;
extern hb_filter_object_t hb_filter_pad;
extern hb_filter_object_t hb_filter_lapsharp;
extern hb_filter_object_t hb_filter_unsharp;
extern hb_filter_object_t hb_filter_avfilter;
extern hb_filter_object_t hb_filter_mt_frame;
extern hb_filter_object_t hb_filter_colorspace;
extern hb_filter_object_t hb_filter_format;

#if defined(__APPLE__)
extern hb_filter_object_t hb_filter_prefilter_vt;
extern hb_filter_object_t hb_filter_comb_detect_vt;
extern hb_filter_object_t hb_filter_yadif_vt;
extern hb_filter_object_t hb_filter_bwdif_vt;
extern hb_filter_object_t hb_filter_crop_scale_vt;
extern hb_filter_object_t hb_filter_chroma_smooth_vt;
extern hb_filter_object_t hb_filter_rotate_vt;
extern hb_filter_object_t hb_filter_grayscale_vt;
extern hb_filter_object_t hb_filter_pad_vt;
extern hb_filter_object_t hb_filter_lapsharp_vt;
extern hb_filter_object_t hb_filter_unsharp_vt;
#endif

extern hb_motion_metric_object_t hb_motion_metric;
extern hb_blend_object_t hb_blend;

#if defined(__APPLE__)
extern hb_motion_metric_object_t hb_motion_metric_vt;
extern hb_blend_object_t hb_blend_vt;
#endif


extern hb_work_object_t * hb_objects;

#define HB_WORK_IDLE     0
#define HB_WORK_OK       1
#define HB_WORK_ERROR    2
#define HB_WORK_DONE     3

/***********************************************************************
 * Muxers
 **********************************************************************/
typedef struct hb_mux_object_s hb_mux_object_t;
typedef struct hb_mux_data_s   hb_mux_data_t;

#define HB_MUX_COMMON \
    int (*init)      ( hb_mux_object_t * ); \
    int (*mux)       ( hb_mux_object_t *, hb_mux_data_t *, \
                       hb_buffer_t * ); \
    int (*end)       ( hb_mux_object_t * );

#define DECLARE_MUX( a ) \
    hb_mux_object_t  * hb_mux_##a##_init( hb_job_t * );

DECLARE_MUX( mp4 );
DECLARE_MUX( mkv );
DECLARE_MUX( webm );
DECLARE_MUX( avformat );

struct hb_chapter_queue_item_s
{
    int64_t start;
    int     new_chap;
};

struct hb_chapter_queue_s
{
    hb_list_t   * list_chapter;
};

typedef struct hb_chapter_queue_item_s hb_chapter_queue_item_t;
typedef struct hb_chapter_queue_s hb_chapter_queue_t;

hb_chapter_queue_t * hb_chapter_queue_init(void);
void                 hb_chapter_queue_close(hb_chapter_queue_t **_q);
void                 hb_chapter_enqueue(hb_chapter_queue_t *q, hb_buffer_t *b);
void                 hb_chapter_dequeue(hb_chapter_queue_t *q, hb_buffer_t *b);

/* Font names used for rendering subtitles */
#if defined(SYS_MINGW)
#define HB_FONT_MONO "Lucida Console"
#define HB_FONT_SANS "sans-serif"
#elif defined(__APPLE__)
// use a different monospace font until https://github.com/libass/libass/issues/518 is resolved
#define HB_FONT_MONO "Andale Mono"
#define HB_FONT_SANS "sans-serif"
#else
#define HB_FONT_MONO "monospace"
#define HB_FONT_SANS "sans-serif"
#endif

#endif // HANDBRAKE_INTERNAL_H
