/* ttsSetParams at runtime: open with alice, then apply "id=value"... from argv, speak to a file. */
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct { int id; union { uint16_t u; char s[128]; } v; } tts_param_t;
int main(int argc, char **argv)
{
    void *l = dlopen("libttsengine.so.1", RTLD_NOW);
    int (*init)(const char *) = dlsym(l, "ttsInitialize");
    int (*open)(tts_param_t *, int) = dlsym(l, "ttsOpenInstance");
    int (*set)(tts_param_t *, int) = dlsym(l, "ttsSetParams");
    int (*speak)(const uint16_t *, size_t, const char *, int, int) = dlsym(l, "ttsStartText2Speech");
    int (*uninit)(void) = dlsym(l, "ttsUnInitialize");
    tts_param_t p[8];
    memset(p, 0, sizeof p);
    init(NULL);
    p[0].id = 8; strcpy(p[0].v.s, "alice");
    printf("open alice %d\n", open(p, 1));
    memset(p, 0, sizeof p);
    int n = 0;
    for (int i = 1; i < argc - 1 && n < 8; i++, n++) {
        char *eq = strchr(argv[i], '=');
        p[n].id = atoi(argv[i]);
        if (eq[1] >= '0' && eq[1] <= '9') p[n].v.u = atoi(eq + 1); else strcpy(p[n].v.s, eq + 1);
    }
    printf("set %d params: %d\n", n, set(p, n));
    uint16_t w[] = { 'H', 'e', 'l', 'l', 'o', ' ', 't', 'h', 'e', 'r', 'e', '.', 0 };
    printf("speak %d\n", speak(w, 24, argv[argc - 1], 0, 0));
    uninit();
    return 0;
}
