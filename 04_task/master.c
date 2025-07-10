#include <stdio.h>
#include <omp.h>

int main() {
    printf("Number of threads: %d\n", omp_get_max_threads());

    #pragma omp parallel
    {
        int thread_id = omp_get_thread_num();
        printf("Thread %d: Before master construct\n", thread_id);

        #pragma omp master
        {
            int executing_thread = omp_get_thread_num();
            printf("Thread %d: Executing master construct\n", executing_thread);
        }

        printf("Thread %d: After master construct\n", thread_id);
    }

    return 0;
}
