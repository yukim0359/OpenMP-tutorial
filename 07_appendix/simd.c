#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define N 100000000
#define SIMD

int main(void) {
    int *a = malloc(sizeof(int) * N);
    int *b = malloc(sizeof(int) * N);
    if (!a || !b) {
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }

    #pragma omp parallel for
    for (int i = 0; i < N; i++) {
        a[i] = (int)(i % 100);
    }

    double t0, t1;

    t0 = omp_get_wtime();
#if defined(SIMD)
    #pragma omp parallel for simd aligned(a,b:64)
#else
    #pragma omp parallel for
#endif
    for (int i = 0; i < N; i++) {
        b[i] = 2 * a[i];
    }
    t1 = omp_get_wtime();

#if defined(SIMD)
    printf("Dot product (SIMD): %.6f sec\n", t1 - t0);
#else
    printf("Dot product (scalar): %.6f sec\n", t1 - t0);
#endif

    free(a); free(b);
    return 0;
}
