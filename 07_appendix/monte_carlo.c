#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <omp.h>

#define NUM_POINTS 1000000000

double random_double(unsigned int *seed) {
    return (double)rand_r(seed) / RAND_MAX;
}

int main() {
    long long total_inside = 0;
    
    double start_time = omp_get_wtime();
    
    #pragma omp parallel
    {
        int thread_id = omp_get_thread_num();
        unsigned int seed = time(NULL) + thread_id;
        
        #pragma omp for schedule(static) reduction(+:total_inside)
        for (long long i = 0; i < NUM_POINTS; i++) {
            double x = 2.0 * random_double(&seed) - 1.0;
            double y = 2.0 * random_double(&seed) - 1.0;
            
            if (x*x + y*y <= 1.0) {
                total_inside++;
            }
        }
    }
    
    double pi = 4.0 * (double)total_inside / NUM_POINTS;
    double end_time = omp_get_wtime();
    
    printf("The number of threads: %d\n", omp_get_max_threads());
    printf("Approximated value of pi: %.10f\n", pi);
    printf("Actual value of pi: %.10f\n", 3.1415926535);
    printf("Error: %.10f\n", fabs(pi - M_PI));
    printf("Execution time: %.6f seconds\n", end_time - start_time);
    
    return 0;
} 
