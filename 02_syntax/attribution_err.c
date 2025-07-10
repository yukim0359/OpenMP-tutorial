#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <omp.h>

#define N 10000

int heavy_task() {
    int repeat = 1000000;
    int sum = 0;
    for (int idx = 0; idx < repeat; idx++) {
        sum += idx;
    }
    return sum;
}

int main() {
    int *a = malloc(N * sizeof(int));
    if (!a) {
        perror("malloc");
        return EXIT_FAILURE;
    }

    for (int idx = 0; idx < N; idx++) a[idx] = 0;

    int i, j;
    #pragma omp parallel for
    for (i = 0; i < N; i++) {
        j = i;
        heavy_task(); // more likely to cause an error
        a[j] = 1;
    }

    long sum = 0;
    for (int idx = 0; idx < N; idx++) sum += a[idx];
    printf("Sum = %ld\n", sum);

    free(a);
    return 0;
}
