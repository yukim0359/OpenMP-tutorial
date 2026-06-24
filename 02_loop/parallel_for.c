#include <stdio.h>
#include <omp.h>

#define N 8

int main() {
    #pragma omp parallel for
    for (int i = 0; i < N; i++) {
        int tid = omp_get_thread_num();
        printf("Loop %d is being processed by thread %d\n", i, tid);
    }
    return 0;
}
