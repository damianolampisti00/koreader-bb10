/* libkotts smoke test: two queued sentences, the second one stopped after 2 s. */
#include <stdio.h>
#include <unistd.h>
typedef struct { int id; int what; } kotts_event_t;
int kotts_init(const char *, const char *, int, int, int);
int kotts_speak(int, const char *);
void kotts_stop(void);
int kotts_poll(kotts_event_t *, int);
void kotts_shutdown(void);
int main(void)
{
    kotts_event_t ev[16];
    printf("init %d\n", kotts_init(NULL, "alice", 100, 100, 100));
    kotts_speak(1, "Prima frase, letta per intero.");
    kotts_speak(2, "Seconda frase, molto più lunga, che verrà interrotta dopo un paio di secondi, prima della fine.");
    for (int t = 0; t < 100; t++) {
        usleep(100000);
        int n = kotts_poll(ev, 16);
        for (int i = 0; i < n; i++) {
            printf("%.1fs id %d what %d\n", t / 10.0, ev[i].id, ev[i].what);
            if (ev[i].id == 2 && ev[i].what == 1) { sleep(2); kotts_stop(); printf("stop\n"); }
        }
    }
    kotts_shutdown();
    printf("done\n");
    return 0;
}
