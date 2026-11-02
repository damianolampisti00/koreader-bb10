/*
 * Probe of BB10's private TTS engine (libttsengine.so.1 → Nuance Vocalizer Expressive),
 * prototypes reverse-engineered from libasr-nuance_tts-prompt.so (the system's "prompt" service).
 *
 * Usage: ttstest [-o out.wav] [-v voice] [-p id=value]... [-d datapath] [-V verbose] "text"
 *   no -o: speak through the audio output.
 */
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Passed as-is to Nuance's ve_ttsSetParamList: VE_PARAM { VE_PARAMID eID; VE_PARAMVALUE uValue; } */
typedef struct {
    int id;
    union {
        uint16_t u;
        char s[128];
    } v;
} tts_param_t;

typedef int (*init_fn)(const char *);
typedef int (*verbose_fn)(int);
typedef int (*params_fn)(tts_param_t *, int);
typedef int (*speak_fn)(const uint16_t *, size_t, const char *, int, int);
typedef int (*void_fn)(void);

static size_t utf8_to_utf16(const char *in, uint16_t *out)
{
    size_t n = 0;
    const unsigned char *p = (const unsigned char *)in;
    while (*p) {
        uint32_t c = *p++;
        if (c >= 0xC0 && c < 0xE0 && *p) {
            c = ((c & 0x1F) << 6) | (*p++ & 0x3F);
        } else if (c >= 0xE0 && c < 0xF0 && p[0] && p[1]) {
            c = ((c & 0x0F) << 12) | ((p[0] & 0x3F) << 6) | (p[1] & 0x3F);
            p += 2;
        } else if (c >= 0xF0 && p[0] && p[1] && p[2]) {
            c = '?';
            p += 3;
        }
        out[n++] = (uint16_t)c;
    }
    out[n] = 0;
    return n;
}

int main(int argc, char **argv)
{
    const char *out = NULL, *voice = "alice", *data = "/usr/tts/nuance/ve/data";
    int verbose = 0, opt, np = 0;
    tts_param_t params[16];

    memset(params, 0, sizeof params);
    while ((opt = getopt(argc, argv, "o:v:p:d:V:")) != -1) {
        switch (opt) {
        case 'o': out = optarg; break;
        case 'v': voice = optarg; break;
        case 'd': data = strcmp(optarg, "-") ? optarg : NULL; break;
        case 'V': verbose = atoi(optarg); break;
        case 'p': {
            char *eq = strchr(optarg, '=');
            if (!eq || np >= 15) return 2;
            params[np].id = atoi(optarg);
            if (eq[1] >= '0' && eq[1] <= '9')
                params[np].v.u = (uint16_t)atoi(eq + 1);
            else
                strncpy(params[np].v.s, eq + 1, sizeof params[np].v.s - 1);
            np++;
            break;
        }
        default: return 2;
        }
    }
    if (optind >= argc) {
        fprintf(stderr, "usage: %s [-o out.wav] [-v voice] [-p id=value]... \"text\"\n", argv[0]);
        return 2;
    }

    void *lib = dlopen("libttsengine.so.1", RTLD_NOW);
    if (!lib) {
        fprintf(stderr, "dlopen: %s\n", dlerror());
        return 1;
    }
    init_fn ttsInitialize = (init_fn)dlsym(lib, "ttsInitialize");
    verbose_fn ttsSetVerboseLevel = (verbose_fn)dlsym(lib, "ttsSetVerboseLevel");
    params_fn ttsOpenInstance = (params_fn)dlsym(lib, "ttsOpenInstance");
    speak_fn ttsStartText2Speech = (speak_fn)dlsym(lib, "ttsStartText2Speech");
    void_fn ttsUnInitialize = (void_fn)dlsym(lib, "ttsUnInitialize");

    ttsSetVerboseLevel(verbose);
    int r = ttsInitialize(data);
    printf("ttsInitialize(%s) = %d\n", data ? data : "NULL", r);
    if (r) return 1;

    /* The voice first (as the prompt service does), then the numeric overrides. */
    tts_param_t all[16];
    memset(all, 0, sizeof all);
    all[0].id = 8;
    strncpy(all[0].v.s, voice, sizeof all[0].v.s - 1);
    memcpy(all + 1, params, np * sizeof *params);
    r = ttsOpenInstance(all, np + 1);
    printf("ttsOpenInstance(voice=%s, %d params) = %d\n", voice, np, r);
    if (r) return 1;

    const char *text = argv[optind];
    uint16_t *w = calloc(strlen(text) + 1, sizeof *w);
    size_t n = utf8_to_utf16(text, w);
    r = ttsStartText2Speech(w, n * 2, out, 0, 0);
    printf("ttsStartText2Speech(%zu chars, %s) = %d\n", n, out ? out : "speaker", r);
    printf("ttsUnInitialize = %d\n", ttsUnInitialize());
    return r ? 1 : 0;
}
