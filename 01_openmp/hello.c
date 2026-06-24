#include <stdio.h>
#include <omp.h>

int main() {
    printf("Before parallel region\n");
    #pragma omp parallel
    {
        int tid = omp_get_thread_num();
        int nthreads = omp_get_num_threads();
        printf("Hello, World! I'm thread %d of %d\n", tid, nthreads);
    }
    printf("After parallel region\n");
    return 0;
}
