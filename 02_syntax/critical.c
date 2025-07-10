#include <stdio.h>
#include <unistd.h>
#include <omp.h>
#include <math.h>

#define N 10000
#define DEBUG 1

int main() {
    double A[N], B[N];

    for (int i = 0; i < N; i++) {
        A[i] = 0.0;
        B[i] = 1.0;
    }

    double t0 = omp_get_wtime();

    #pragma omp parallel for
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            #pragma omp critical
            {
                A[j] += 2.0 * B[i];
            }
        }
    }

    double t1 = omp_get_wtime();

    if(DEBUG){
        int all_correct = 1;
        for (int i = 0; i < N; i++) {
            if (fabs(A[i] - 2.0 * N) > 1e-6) {
                all_correct = 0;
                printf("Error: A[%d] = %f (expected %f)\n", i, A[i], 2.0 * N);
                break;
            }
        }
        if (all_correct) {
            printf("OK: All elements are equal to %f\n", 2.0 * N);
        }
    }

    printf("Elapsed time: %f seconds\n", t1 - t0);
    return 0;
}
