#include <math.h>
#include <stdio.h>
#include <omp.h>

#define N 1024
#define TILE 64

static double A[N][N], B[N][N], C[N][N];

static void init_matrix(void)
{
#pragma omp parallel for collapse(2)
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            A[i][j] = 1.0;
            B[i][j] = 2.0;
            C[i][j] = 0.0;
        }
    }
}

static void matmul_tuned(void)
{
#pragma omp parallel for schedule(static)
    for (int ii = 0; ii < N; ii += TILE) {
        for (int kk = 0; kk < N; kk += TILE) {
            for (int jj = 0; jj < N; jj += TILE) {
                int i_end = (ii + TILE < N) ? ii + TILE : N;
                int k_end = (kk + TILE < N) ? kk + TILE : N;
                int j_end = (jj + TILE < N) ? jj + TILE : N;
                for (int i = ii; i < i_end; i++) {
                    for (int k = kk; k < k_end; k++) {
                        double a_ik = A[i][k];
                        for (int j = jj; j < j_end; j++) {
                            C[i][j] += a_ik * B[k][j];
                        }
                    }
                }
            }
        }
    }
}

int main(void)
{
    init_matrix();

    double t0 = omp_get_wtime();
    matmul_tuned();
    double t1 = omp_get_wtime();

    printf("N=%d, threads=%d, time=%f sec\n", N, omp_get_max_threads(), t1 - t0);

    double expected = (double)N * 2.0;
    int ok = 1;
    for (int i = 0; i < N && ok; i++) {
        for (int j = 0; j < N && ok; j++) {
            if (fabs(C[i][j] - expected) > 1e-6) {
                ok = 0;
            }
        }
    }
    printf("%s\n", ok ? "Test passed!" : "Test failed!");
    return ok ? 0 : 1;
}
