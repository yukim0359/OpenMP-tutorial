#include <omp.h>

void omp_atomic_double_add(double *a, double b) {
    #pragma omp atomic
    *a += 2.0 * b;
}
