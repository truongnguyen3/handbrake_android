#ifndef JANSSON_H
#define JANSSON_H

/* Minimal jansson.h stub for HandBrake Android build */

#ifdef __cplusplus
extern "C" {
#endif

/* Basic types */
typedef struct json_t json_t;

/* JSON types */
typedef enum {
    JSON_OBJECT,
    JSON_ARRAY,
    JSON_STRING,
    JSON_INTEGER,
    JSON_REAL,
    JSON_TRUE,
    JSON_FALSE,
    JSON_NULL
} json_type;

/* Basic functions - all return null/fail in stub implementation */
static inline json_t *json_object(void) { return (json_t*)0; }
static inline json_t *json_array(void) { return (json_t*)0; }
static inline json_t *json_string(const char *value) { return (json_t*)0; }
static inline json_t *json_integer(long value) { return (json_t*)0; }
static inline json_t *json_real(double value) { return (json_t*)0; }
static inline json_t *json_true(void) { return (json_t*)0; }
static inline json_t *json_false(void) { return (json_t*)0; }
static inline json_t *json_null(void) { return (json_t*)0; }

static inline void json_decref(json_t *json) { }
static inline json_t *json_incref(json_t *json) { return json; }

static inline int json_object_set_new(json_t *object, const char *key, json_t *value) { return -1; }
static inline int json_array_append_new(json_t *array, json_t *value) { return -1; }

static inline json_t *json_object_get(const json_t *object, const char *key) { return (json_t*)0; }
static inline json_t *json_array_get(const json_t *array, size_t index) { return (json_t*)0; }

static inline char *json_dumps(const json_t *json, size_t flags) { return (char*)0; }
static inline json_t *json_loads(const char *input, size_t flags, void *error) { return (json_t*)0; }

#ifdef __cplusplus
}
#endif

#endif /* JANSSON_H */