#ifndef X264_H
#define X264_H

// Minimal x264 header stub for compilation
typedef struct {
    int dummy;
} x264_param_t;

typedef struct {
    int dummy;
} x264_t;

#ifdef __cplusplus
extern "C" {
#endif

// Minimal function stubs
void x264_param_default(x264_param_t *param);
x264_t *x264_encoder_open(x264_param_t *param);
void x264_encoder_close(x264_t *h);

#ifdef __cplusplus
}
#endif

#endif /* X264_H */
