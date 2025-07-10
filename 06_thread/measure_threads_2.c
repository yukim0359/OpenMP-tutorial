#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define N 10000

int main(int argc, char *argv[]) {
    int num_threads = omp_get_max_threads();
    if (argc > 1) {
        num_threads = atoi(argv[1]);
        if (num_threads < 1) num_threads = omp_get_max_threads();
    }
    omp_set_num_threads(num_threads);

    long counter = 0;

    double t0 = omp_get_wtime();

    #pragma omp parallel for
    for (long i = 0; i < N; i++) {
        /* When the ratio of non-atomic operations is high, 
            performance improvement can be observed with increasing thread count */
        // for(long j = 0; j < 100; j++) {
        //     long tmp = (long)i * (long)j;
        // }
        #pragma omp atomic
        counter++;
    }

    double t1 = omp_get_wtime();

    printf("%d %f\n", num_threads, t1 - t0);
    return 0;
}
