#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define N 50000

int main() {
    int *A = malloc(sizeof(int) * N);
    if (!A) {
        perror("malloc");
        return EXIT_FAILURE;
    }

    int i, j;
    int threads = omp_get_max_threads();
    double t0, t1;
    printf("=== OpenMP threads: %d ===\n", threads);

    int thread_ids[N];

    for (i = 0; i < N; i++) A[i] = 0;

    t0 = omp_get_wtime();
    #pragma omp parallel for schedule(static) private(i,j)
    for (i = 0; i < N; i++) {
        thread_ids[i] = omp_get_thread_num();
        for (j = 0; j < i; j++) {
            A[i]++;
        }
        if (A[i] != i) {
            printf("Error: A[%d] = %d, expected %d\n", i, A[i], i);
        }
    }
    t1 = omp_get_wtime();
    printf("static : %f s\n", t1 - t0);

    FILE *fp = fopen("csv/static_data.csv", "w");
    if (!fp) {
        perror("fopen");
        free(A);
        return EXIT_FAILURE;
    }
    fprintf(fp, "iteration,thread\n");
    for (int i = 0; i < N; i++) {
        fprintf(fp, "%d,%d\n", i, thread_ids[i]);
    }
    fclose(fp);

    free(A);
    return 0;
}
