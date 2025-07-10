#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

// Merge function: merge a[left:mid) and a[mid:right) using tmp, and store the result in a[left:right)
void merge_range(int *a, int *tmp, int left, int mid, int right) {
    int i = left, j = mid, k = left;
    while (i < mid && j < right) {
        tmp[k++] = (a[i] <= a[j]) ? a[i++] : a[j++];
    }
    while (i < mid) tmp[k++] = a[i++];
    while (j < right) tmp[k++] = a[j++];
    memcpy(a + left, tmp + left, (right - left) * sizeof(int));
}

// Recursive function: sort a[left:right)
void parallel_merge_sort_rec(int *a, int *tmp, int left, int right, int threshold) {
    int len = right - left;
    if (len <= threshold) {
        for (int i = left + 1; i < right; i++) {
            int key = a[i], j = i - 1;
            while (j >= left && a[j] > key) {
                a[j + 1] = a[j];
                j--;
            }
            a[j + 1] = key;
        }
        return;
    }
    int mid = left + len / 2;

    #pragma omp task shared(a, tmp) firstprivate(left, mid, threshold)
    parallel_merge_sort_rec(a, tmp, left, mid, threshold);

    #pragma omp task shared(a, tmp) firstprivate(mid, right, threshold)
    parallel_merge_sort_rec(a, tmp, mid, right, threshold);

    #pragma omp taskwait

    merge_range(a, tmp, left, mid, right);
}

void parallel_merge_sort(int *a, int n) {
    int *tmp = malloc(n * sizeof(int));
    if (!tmp) {
        fprintf(stderr, "Memory allocation error\n");
        exit(EXIT_FAILURE);
    }

    #pragma omp parallel
    {
        #pragma omp single
        parallel_merge_sort_rec(a, tmp, 0, n, /*threshold=*/64);
    }

    free(tmp);
}

int main() {
    const int N = 100000;
    int *a = malloc(N * sizeof(int));
    for (int i = 0; i < N; i++) a[i] = rand();

    double start_time = omp_get_wtime();
    parallel_merge_sort(a, N);
    double end_time = omp_get_wtime();

    for (int i = 1; i < N; i++) {
        if (a[i-1] > a[i]) {
            fprintf(stderr, "Error at %d\n", i);
            break;
        }
    }
    printf("Sorting completed\n");
    printf("Time: %f s\n", end_time - start_time);
    free(a);
    return 0;
}
