#include <stdio.h>
#include <omp.h>

int main() {
    printf("Number of threads: %d\n", omp_get_max_threads());

    #pragma omp parallel
    {
        int thread_id = omp_get_thread_num();
        printf("Thread %d: Before single construct\n", thread_id);

        #pragma omp single
        {
            int executing_thread = omp_get_thread_num();
            printf("Thread %d: Executing single construct\n", executing_thread);
        }

        printf("Thread %d: After single construct\n", thread_id);

        #pragma omp single nowait
        {
            printf("Thread %d: Executing single nowait construct\n", omp_get_thread_num());
        }
        printf("Thread %d: After single nowait construct\n", thread_id);
    }

    return 0;
}
