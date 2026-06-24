#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include "hist_common.h"

#ifndef N
#define N 20000000
#endif

int main(int argc, char *argv[]) {
    int num_threads = omp_get_max_threads();
    int skewed = 0;

    if (argc > 1) {
        num_threads = atoi(argv[1]);
        if (num_threads < 1) {
            num_threads = omp_get_max_threads();
        }
    }
    if (argc > 2 && strcmp(argv[2], "skewed") == 0) {
        skewed = 1;
    }

    omp_set_num_threads(num_threads);

    int *data = malloc(sizeof(int) * N);
    long hist[NBINS] = {0};
    if (!data) {
        perror("malloc");
        return EXIT_FAILURE;
    }

    fill_data(data, N, NBINS, skewed);

    double t0 = omp_get_wtime();

    #pragma omp parallel for
    for (long i = 0; i < N; i++) {
        int bin = data[i];
        #pragma omp atomic
        hist[bin]++;
    }

    double t1 = omp_get_wtime();

    printf("%d %f\n", num_threads, t1 - t0);

    free(data);
    return 0;
}
