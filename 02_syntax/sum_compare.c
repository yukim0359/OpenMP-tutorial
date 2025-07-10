#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

#define N 1000000
#define REPEATS 2

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s [reduction|atomic|private-array]\n", argv[0]);
        return EXIT_FAILURE;
    }
    const char *method = argv[1];
    double *A = malloc(sizeof(double) * N);
    double *B = malloc(sizeof(double) * N);
    if (!A || !B) {
        perror("malloc");
        return EXIT_FAILURE;
    }

    for (long i = 0; i < N; i++) {
        A[i] = 1.0;
        B[i] = 2.0;
    }

    double t0, t1;
    int nthreads = omp_get_max_threads();
    printf("Elements: %d, Threads: %d\n", N, nthreads);

    if (strcmp(method, "reduction") == 0) {
        double sum1 = 0.0;
        // 1st run (warm-up)
        #pragma omp parallel for reduction(+:sum1)
        for (int i = 0; i < N; i++) {
            sum1 += A[i] * B[i];
        }
        sum1 = 0.0;
        t0 = omp_get_wtime();
        #pragma omp parallel for reduction(+:sum1)
        for (int i = 0; i < N; i++) {
            sum1 += A[i] * B[i];
        }
        t1 = omp_get_wtime();
        printf("1) reduction     : sum = %.6f  time = %.6f s\n", sum1, t1 - t0);
    } else if (strcmp(method, "atomic") == 0) {
        double sum2 = 0.0;
        // 1st run (warm-up)
        #pragma omp parallel for
        for (int i = 0; i < N; i++) {
            double tmp = A[i] * B[i];
            #pragma omp atomic
            sum2 += tmp;
        }
        sum2 = 0.0;
        t0 = omp_get_wtime();
        #pragma omp parallel for
        for (int i = 0; i < N; i++) {
            double tmp = A[i] * B[i];
            #pragma omp atomic
            sum2 += tmp;
        }
        t1 = omp_get_wtime();
        printf("2) atomic        : sum = %.6f  time = %.6f s\n", sum2, t1 - t0);
    } else if (strcmp(method, "private-array") == 0) {
        double *sum_local = malloc(sizeof(double) * nthreads);
        if (!sum_local) {
            perror("malloc");
            return EXIT_FAILURE;
        }
        for (int t = 0; t < nthreads; t++) sum_local[t] = 0.0;
        // 1st run (warm-up)
        #pragma omp parallel
        {
            int tid = omp_get_thread_num();
            #pragma omp for
            for (int i = 0; i < N; i++) {
                sum_local[tid] += A[i] * B[i];
            }
        }
        for (int t = 0; t < nthreads; t++) sum_local[t] = 0.0;
        t0 = omp_get_wtime();
        #pragma omp parallel
        {
            int tid = omp_get_thread_num();
            #pragma omp for
            for (int i = 0; i < N; i++) {
                sum_local[tid] += A[i] * B[i];
            }
        }
        double sum3 = 0.0;
        for (int t = 0; t < nthreads; t++) {
            sum3 += sum_local[t];
        }
        t1 = omp_get_wtime();
        printf("3) private-array : sum = %.6f  time = %.6f s\n", sum3, t1 - t0);
        free(sum_local);
    } else {
        fprintf(stderr, "Unknown method: %s\n", method);
        return EXIT_FAILURE;
    }

    free(A); free(B);
    return 0;
}
