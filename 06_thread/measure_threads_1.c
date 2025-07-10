#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define N 1000

int main(int argc, char *argv[]) {
    int num_threads = omp_get_max_threads();
    if (argc > 1) {
        num_threads = atoi(argv[1]);
        if (num_threads < 1) num_threads = omp_get_max_threads();
    }
    omp_set_num_threads(num_threads);

    double **A = malloc(sizeof(double*) * N);
    double **B = malloc(sizeof(double*) * N);
    double **C = malloc(sizeof(double*) * N);
    if (!A || !B || !C) {
        perror("malloc");
        return EXIT_FAILURE;
    }

    for (int i = 0; i < N; i++) {
        A[i] = malloc(sizeof(double) * N);
        B[i] = malloc(sizeof(double) * N);
        C[i] = malloc(sizeof(double) * N);
        if (!A[i] || !B[i] || !C[i]) {
            perror("malloc");
            return EXIT_FAILURE;
        }
    }

    #pragma omp parallel for collapse(2)
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            A[i][j] = 1.0;
            B[i][j] = 2.0;
            C[i][j] = 0.0;
        }
    }

    double t0 = omp_get_wtime();

    #pragma omp parallel for collapse(2)
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            double sum = 0.0;
            for (int k = 0; k < N; k++) {
                sum += A[i][k] * B[k][j];
            }
            C[i][j] = sum;
        }
    }

    double t1 = omp_get_wtime();

    printf("%d %f\n", num_threads, t1 - t0);

    for (int i = 0; i < N; i++) {
        free(A[i]);
        free(B[i]);
        free(C[i]);
    }
    free(A);
    free(B);
    free(C);
    return 0;
}
