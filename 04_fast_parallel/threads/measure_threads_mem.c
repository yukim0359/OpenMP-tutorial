#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

/* メモリ帯域が律速になりやすい配列演算 */
#ifndef N
#define N 20000000
#endif

int main(int argc, char *argv[]) {
    int num_threads = omp_get_max_threads();
    if (argc > 1) {
        num_threads = atoi(argv[1]);
        if (num_threads < 1) num_threads = omp_get_max_threads();
    }
    omp_set_num_threads(num_threads);

    double *A = malloc(sizeof(double) * N);
    double *B = malloc(sizeof(double) * N);
    double *C = malloc(sizeof(double) * N);
    if (!A || !B || !C) {
        perror("malloc");
        return EXIT_FAILURE;
    }

    #pragma omp parallel for
    for (long i = 0; i < N; i++) {
        B[i] = 1.0;
        C[i] = 2.0;
    }

    double t0 = omp_get_wtime();

    #pragma omp parallel for
    for (long i = 0; i < N; i++) {
        A[i] = B[i] + 2.0 * C[i];
    }

    double t1 = omp_get_wtime();

    printf("%d %f\n", num_threads, t1 - t0);

    free(A);
    free(B);
    free(C);
    return 0;
}
