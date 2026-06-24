#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <math.h>

#define N 1024
#define DEBUG 1
#define USE_COLLAPSE

static double A[N][N], B[N][N], C[N][N];

void init_matrix() {
    int i, j;
    if (DEBUG) {
        for (i = 0; i < N; i++) {
            for (j = 0; j < N; j++) {
                A[i][j] = 1.0;
                B[i][j] = 1.0;
                C[i][j] = 0.0;
            }
        }
    } else{
        for (i = 0; i < N; i++) {
            for (j = 0; j < N; j++) {
                A[i][j] = rand();
                B[i][j] = rand();
                C[i][j] = 0.0;
            }
        }
    }
}

int main() {
    double start_time, end_time;

    init_matrix();

    start_time = omp_get_wtime();
    #pragma omp target data map(to:A[0:N][0:N], B[0:N][0:N]) map(from:C[0:N][0:N])
    {
#ifdef USE_COLLAPSE
        #pragma omp target teams distribute parallel for collapse(2)
#else
        #pragma omp target teams distribute parallel for
#endif
        for(int i = 0; i < N; i++) {
            for(int j = 0; j < N; j++) {
                for(int k = 0; k < N; k++) {
                    C[i][j] += A[i][k] * B[k][j];
                }
            }
        }
    }
    end_time = omp_get_wtime();

#ifdef USE_COLLAPSE
    printf("Use collapse\n");
#else
    printf("No collapse\n");
#endif

    if(DEBUG) {
        for(int i = 0; i < N; i++) {
            for(int j = 0; j < N; j++) {
                if(fabs(C[i][j] - N) > 1e-6) {
                    printf("Error: C[%d][%d] = %f, expected %d\n", i, j, C[i][j], N);
                    return 0;
                }
            }
        }
        printf("Test passed!\n");
    }
    printf("Computation time: %f seconds\n", end_time - start_time);

    return 0;
} 
