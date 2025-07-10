#include <omp.h>

void omp_atomic_int_add(int *a, int b) {
    #pragma omp atomic
    *a += b;
}
