#include <stdio.h>
#include <omp.h>

#define N 50
#define ENABLE_TASK_PARALLEL

#ifdef ENABLE_TASK_PARALLEL
long fib(int n) {
    if (n < 2) return n;
    else {
        long x, y;
        if (n < 20) {
            x = fib(n - 1);
            y = fib(n - 2);
        } else {
            #pragma omp task shared(x) firstprivate(n)
            x = fib(n - 1);
            #pragma omp task shared(y) firstprivate(n)
            y = fib(n - 2);
            #pragma omp taskwait
        }
        return x + y;
    }
}
#else
long fib(int n) {
    if (n < 2) return n;
    else return fib(n - 1) + fib(n - 2);
}
#endif

int main() {
    double t0 = omp_get_wtime();
#ifdef ENABLE_TASK_PARALLEL
    printf("OpenMP version\n");
    printf("threads: %d\n", omp_get_max_threads());
    #pragma omp parallel
    {
        #pragma omp master
        printf("Fibonacci of %d is %ld\n", N, fib(N));
    }
    double t1 = omp_get_wtime();
    printf("Elapsed time: %f seconds\n", t1 - t0);
#else
    printf("serial version\n");
    printf("Fibonacci of %d is %ld\n", N, fib(N));
    double t1 = omp_get_wtime();
    printf("Elapsed time: %f seconds\n", t1 - t0);
#endif
    return 0;
}
