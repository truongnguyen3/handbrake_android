/* Android stub implementations for disabled features */

#include "handbrake/handbrake.h"
#include "handbrake/internal.h"

#ifdef USE_HB_ANDROID

// DVD stub functions
hb_dvd_t * hb_dvd_init( hb_handle_t * h, const char * path )
{
    return NULL;
}

void hb_dvd_close( hb_dvd_t ** _d )
{
    // No-op
}

int hb_dvd_title_count( hb_dvd_t * d )
{
    return 0;
}

hb_title_t * hb_dvd_title_scan( hb_dvd_t * d, int title, uint64_t min_duration, uint64_t max_duration )
{
    return NULL;
}

int hb_dvd_start( hb_dvd_t * d, hb_title_t * title, int chapter )
{
    return 0;
}

void hb_dvd_stop( hb_dvd_t * d )
{
    // No-op
}

int hb_dvd_seek( hb_dvd_t * d, float f )
{
    return 0;
}

hb_buffer_t * hb_dvd_read( hb_dvd_t * d )
{
    return NULL;
}

int hb_dvd_chapter( hb_dvd_t * d )
{
    return 0;
}

int hb_dvd_angle_count( hb_dvd_t * d )
{
    return 1;
}

void hb_dvd_set_angle( hb_dvd_t * d, int angle )
{
    // No-op
}

int hb_dvd_main_feature( hb_dvd_t * d, hb_list_t * list_title )
{
    return 0;
}

// BluRay stub functions
hb_bd_t * hb_bd_init( hb_handle_t *h, const char * path, int keep_duplicate_titles )
{
    return NULL;
}

void hb_bd_close( hb_bd_t ** _d )
{
    // No-op
}

int hb_bd_title_count( hb_bd_t * d )
{
    return 0;
}

hb_title_t * hb_bd_title_scan( hb_bd_t * d, int t, uint64_t min_duration, uint64_t max_duration )
{
    return NULL;
}

int hb_bd_start( hb_bd_t * d, hb_title_t * title )
{
    return 0;
}

void hb_bd_stop( hb_bd_t * d )
{
    // No-op
}

int hb_bd_seek( hb_bd_t * d, float f )
{
    return 0;
}

hb_buffer_t * hb_bd_read( hb_bd_t * d )
{
    return NULL;
}

int hb_bd_chapter( hb_bd_t * d )
{
    return 0;
}

// Added missing functions
int hb_bd_seek_pts( hb_bd_t * d, uint64_t pts )
{
    return 0;
}

int hb_bd_seek_chapter( hb_bd_t * d, int chapter )
{
    return 0;
}

// iconv stubs for text conversion (disabled on Android)
typedef void* iconv_t;

iconv_t iconv_open(const char *tocode, const char *fromcode)
{
    return (iconv_t)-1;  // Return error
}

size_t iconv(iconv_t cd, char **inbuf, size_t *inbytesleft, char **outbuf, size_t *outbytesleft)
{
    return (size_t)-1;  // Return error
}

int iconv_close(iconv_t cd)
{
    return -1;  // Return error
}

// SVT-AV1 encoder stubs (disabled on Android)
typedef void* SvtAv1EncConfiguration;
typedef void* EbComponentType;
typedef void* EbBufferHeaderType;
typedef void* EbSvtAv1EncConfiguration;

int svt_av1_enc_init_handle(EbComponentType **p_handle, void *p_app_data, EbSvtAv1EncConfiguration *config_ptr)
{
    return -1;  // Return error
}

int svt_av1_enc_parse_parameter(EbSvtAv1EncConfiguration *config, const char *key, const char *value)
{
    return -1;  // Return error
}

int svt_av1_enc_set_parameter(EbComponentType *svt_enc_component, EbSvtAv1EncConfiguration *config)
{
    return -1;  // Return error
}

int svt_av1_enc_init(EbComponentType *svt_enc_component)
{
    return -1;  // Return error
}

int svt_av1_enc_stream_header(EbComponentType *svt_enc_component, EbBufferHeaderType **output_stream_ptr)
{
    return -1;  // Return error
}

void svt_av1_enc_stream_header_release(EbBufferHeaderType *stream_header_ptr)
{
    // No-op
}

int svt_av1_enc_get_stream_info(EbComponentType *svt_enc_component, int stream_info_id, void *info)
{
    return -1;  // Return error
}

void svt_av1_enc_deinit(EbComponentType *svt_enc_component)
{
    // No-op
}

void svt_av1_enc_deinit_handle(EbComponentType *svt_enc_component)
{
    // No-op
}

void svt_metadata_array_free(void **metadata_array)
{
    // No-op
}

int svt_add_metadata(void **metadata_array, int metadata_type, void *metadata, int metadata_size)
{
    return -1;  // Return error
}

int svt_av1_enc_send_picture(EbComponentType *svt_enc_component, EbBufferHeaderType *p_buffer)
{
    return -1;  // Return error
}

int svt_av1_enc_get_packet(EbComponentType *svt_enc_component, EbBufferHeaderType **p_buffer, int pic_send_done)
{
    return -1;  // Return error
}

void svt_av1_enc_release_out_buffer(EbBufferHeaderType **p_buffer)
{
    // No-op
}

void hb_bd_set_angle( hb_bd_t * d, int angle )
{
    // No-op
}

int hb_bd_main_feature( hb_bd_t * d, hb_list_t * list_title )
{
    return 0;
}

// SVT-AV1 encoder stub (disabled for Android)
static int svtav1_init(hb_work_object_t *w, hb_job_t *job)
{
    return -1; // Error - encoder not available
}

static int svtav1_work(hb_work_object_t *w, hb_buffer_t **buf_in, hb_buffer_t **buf_out)
{
    return HB_WORK_ERROR; // Signal error immediately
}

static void svtav1_close(hb_work_object_t *w)
{
    // No-op
}

hb_work_object_t hb_encsvtav1 =
{
    WORK_ENCSVTAV1,
    "SVT-AV1 encoder (disabled)",
    svtav1_init,
    svtav1_work,
    svtav1_close
};

#endif // USE_HB_ANDROID
