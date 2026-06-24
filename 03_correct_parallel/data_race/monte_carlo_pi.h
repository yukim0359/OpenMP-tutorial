#ifndef MONTE_CARLO_PI_H
#define MONTE_CARLO_PI_H

#include <stdio.h>

#ifndef N
#define N 20000000
#endif
#ifndef SEED
#define SEED 42
#endif
#ifndef SUBSAMPLES
#define SUBSAMPLES 16
#endif

static unsigned rng_state(int trial, int sub) {
    return (unsigned)trial * 2654435761u
         ^ (unsigned)sub * 1597334677u
         ^ (unsigned)SEED * 2246822519u;
}

static long long trial_hits(int trial) {
    unsigned state = rng_state(trial, 0);
    long long hits = 0;
    for (int s = 0; s < SUBSAMPLES; s++) {
        state = state * 1664525u + 1013904223u;
        double x = (state & 0xFFFFFF) / (double)0x1000000;
        state = state * 1664525u + 1013904223u;
        double y = (state & 0xFFFFFF) / (double)0x1000000;
        if (x * x + y * y <= 1.0) {
            hits++;
        }
    }
    return hits;
}

static long long reference_hits(void) {
    long long total = 0;
    for (int i = 0; i < N; i++) {
        total += trial_hits(i);
    }
    return total;
}

static void report_result(long long hits, double elapsed) {
    const long long samples = (long long)N * SUBSAMPLES;
    const double pi_est = 4.0 * (double)hits / (double)samples;
    printf("Elapsed time: %f seconds\n", elapsed);
    printf(
        "Samples: %d trials x %d darts = %lld, hits: %lld, pi estimate: %.6f\n",
        N, SUBSAMPLES, samples, hits, pi_est
    );
}

#endif
