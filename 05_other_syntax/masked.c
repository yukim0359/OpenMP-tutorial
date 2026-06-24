#include <stdio.h>
#include <omp.h>

int main(void) {
    printf("Number of threads: %d\n", omp_get_max_threads());

    #pragma omp parallel
    {
        int thread_id = omp_get_thread_num();
        printf("Thread %d: Before masked construct\n", thread_id);

        #pragma omp masked
        {
            int executing_thread = omp_get_thread_num();
            printf("Thread %d: Executing masked construct\n", executing_thread);
        }

        printf("Thread %d: After masked construct (no implicit barrier)\n", thread_id);
    }

    return 0;
}
