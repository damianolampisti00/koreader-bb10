/* libkotts: voice switch between two utterances (alice, then ava). */
#include <stdio.h>
#include <unistd.h>
typedef struct { int id; int what; } kotts_event_t;
int kotts_init(const char *, const char *, int, int, int);
void kotts_set_voice(const char *);
int kotts_speak(int, const char *);
int kotts_poll(kotts_event_t *, int);
void kotts_shutdown(void);
int main(void)
{
    kotts_event_t ev[16];
    int done = 0;
    printf("init %d\n", kotts_init(NULL, "alice", 100, 100, 100));
    kotts_speak(1, "Questa è Alice.");
    for (int t = 0; t < 200 && done < 2; t++) {
        usleep(100000);
        int n = kotts_poll(ev, 16);
        for (int i = 0; i < n; i++) {
            printf("%.1fs id %d what %d\n", t / 10.0, ev[i].id, ev[i].what);
            if (ev[i].what >= 2 && ++done == 1) { kotts_set_voice("ava"); kotts_speak(2, "And this is Ava, speaking English."); }
        }
    }
    kotts_shutdown();
    return 0;
}
