#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#ifndef N
#define N 200000
#endif

#ifndef WORK
#define WORK 1000
#endif

int main(int argc, char *argv[]) {
    int num_threads = omp_get_max_threads();

    if (argc > 1) {
        num_threads = atoi(argv[1]);
        if (num_threads < 1) num_threads = omp_get_max_threads();
    }

    omp_set_num_threads(num_threads);

    double *out = malloc(sizeof(double) * (size_t)N);
    if (!out) {
        perror("malloc");
        return EXIT_FAILURE;
    }

    double t0 = omp_get_wtime();

    #pragma omp parallel for
    for (long i = 0; i < N; i++) {
        double x = 1.0 + 1.0e-9 * i;

        for (int k = 0; k < WORK; k++) {
            x = x * 1.0000001 + 0.0000001;
            x = x * 0.9999999 + 0.0000002;
        }

        out[i] = x;
    }

    double t1 = omp_get_wtime();

    double checksum = 0.0;
    for (long i = 0; i < N; i++) {
        checksum += out[i];
    }

    printf("%d %f\n", num_threads, t1 - t0);

    free(out);
    if (checksum < 0.0) {
        fprintf(stderr, "checksum=%f\n", checksum);
    }
    return 0;
}
