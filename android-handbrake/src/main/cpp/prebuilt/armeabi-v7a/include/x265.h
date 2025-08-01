#ifndef X265_H
#define X265_H

// Minimal x265 header stub for compilation
typedef struct {
    int dummy;
} x265_param;

typedef struct {
    int dummy;
} x265_encoder;

#ifdef __cplusplus
extern "C" {
#endif

// Minimal function stubs
void x265_param_default(x265_param *param);
x265_encoder *x265_encoder_open(x265_param *param);
void x265_encoder_close(x265_encoder *encoder);

#ifdef __cplusplus
}
#endif

#endif /* X265_H */
