#include <stdlib.h>
#include <omp.h>
#include "monte_carlo_pi.h"

int main(void) {
    long long hits = 0;

    omp_lock_t lock;
    omp_init_lock(&lock);

    double t0 = omp_get_wtime();

    #pragma omp parallel for
    for (int i = 0; i < N; i++) {
        long long h = trial_hits(i);
        omp_set_lock(&lock);
        hits += h;
        omp_unset_lock(&lock);
    }

    double t1 = omp_get_wtime();

    long long expected = reference_hits();
    if (hits != expected) {
        printf("Error: hits = %lld (expected %lld)\n", hits, expected);
    }

    report_result(hits, t1 - t0);

    omp_destroy_lock(&lock);
    return 0;
}
