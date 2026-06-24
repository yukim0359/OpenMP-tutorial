#include <stdlib.h>
#include <omp.h>
#include "monte_carlo_pi.h"

int main(void) {
    long long hits = 0;

    double t0 = omp_get_wtime();

    for (int i = 0; i < N; i++) {
        hits += trial_hits(i);
    }

    double t1 = omp_get_wtime();

    long long expected = reference_hits();
    if (hits != expected) {
        printf("Error: hits = %lld (expected %lld)\n", hits, expected);
    }

    report_result(hits, t1 - t0);
    return 0;
}
