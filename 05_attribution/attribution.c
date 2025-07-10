#include <stdio.h>
#include <omp.h>

int main() {
    int S = 1;
    int P = 2;
    int FP = 3;
    int LP = 4;
    printf("I'm the main thread\nS = %12d at %p, P = %12d at %p, FP = %12d at %p, LP = %12d at %p\n", S, &S, P, &P, FP, &FP, LP, &LP);

    #pragma omp parallel for shared(S) private(P) firstprivate(FP) lastprivate(LP)
    for (int i = 0; i < omp_get_num_threads(); i++) {
        printf("I'm thread %d\nS = %12d at %p, P = %12d at %p, FP = %12d at %p, LP = %12d at %p\n", omp_get_thread_num(), S, &S, P, &P, FP, &FP, LP, &LP);
    }
    
    printf("I'm the main thread\nS = %12d at %p, P = %12d at %p, FP = %12d at %p, LP = %12d at %p\n", S, &S, P, &P, FP, &FP, LP, &LP);
    return 0;
}
