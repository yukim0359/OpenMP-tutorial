#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

static void insertion_sort(int *a, int left, int right) {
    for (int i = left + 1; i < right; i++) {
        int key = a[i], j = i - 1;
        while (j >= left && a[j] > key) {
            a[j + 1] = a[j];
            j--;
        }
        a[j + 1] = key;
    }
}

static void serial_merge_ranges(
    int *dst,
    int dst_off,
    const int *src,
    int l1,
    int r1,
    int l2,
    int r2
) {
    int i = l1, j = l2, k = dst_off;
    while (i < r1 && j < r2) {
        dst[k++] = (src[i] <= src[j]) ? src[i++] : src[j++];
    }
    while (i < r1) dst[k++] = src[i++];
    while (j < r2) dst[k++] = src[j++];
}

static int lower_bound_idx(const int *a, int lo, int hi, int key) {
    while (lo < hi) {
        int m = lo + (hi - lo) / 2;
        if (a[m] < key) lo = m + 1;
        else hi = m;
    }
    return lo;
}

static void cilk_merge_ranges(
    int *dst,
    int dst_off,
    const int *src,
    int l1,
    int r1,
    int l2,
    int r2,
    int threshold
) {
    int n1 = r1 - l1;
    int n2 = r2 - l2;
    if (n1 + n2 <= threshold) {
        serial_merge_ranges(dst, dst_off, src, l1, r1, l2, r2);
        return;
    }

    if (n1 > n2) {
        int i = l1 + n1 / 2;
        int key = src[i];
        int j = lower_bound_idx(src, l2, r2, key);
        int out_mid = dst_off + (i - l1) + (j - l2);

        #pragma omp task shared(dst, src) firstprivate(dst_off, l1, i, l2, j, r1, r2, threshold, out_mid)
        cilk_merge_ranges(dst, dst_off, src, l1, i, l2, j, threshold);

        cilk_merge_ranges(dst, out_mid, src, i, r1, j, r2, threshold);
        #pragma omp taskwait
        return;
    }

    int j = l2 + n2 / 2;
    int key = src[j];
    int i = lower_bound_idx(src, l1, r1, key);
    int out_mid = dst_off + (i - l1) + (j - l2);

    #pragma omp task shared(dst, src) firstprivate(dst_off, l1, i, l2, j, r1, r2, threshold, out_mid)
    cilk_merge_ranges(dst, dst_off, src, l1, i, l2, j, threshold);

    cilk_merge_ranges(dst, out_mid, src, i, r1, j, r2, threshold);
    #pragma omp taskwait
}

static void cilksort_rec(
    int *a,
    int *tmp,
    int left,
    int right,
    int sort_threshold,
    int merge_threshold
) {
    int len = right - left;
    if (len <= sort_threshold) {
        insertion_sort(a, left, right);
        return;
    }
    int mid = left + len / 2;

    #pragma omp task shared(a, tmp) firstprivate(left, mid, sort_threshold, merge_threshold)
    cilksort_rec(a, tmp, left, mid, sort_threshold, merge_threshold);

    #pragma omp task shared(a, tmp) firstprivate(mid, right, sort_threshold, merge_threshold)
    cilksort_rec(a, tmp, mid, right, sort_threshold, merge_threshold);

    #pragma omp taskwait

    cilk_merge_ranges(tmp, left, a, left, mid, mid, right, merge_threshold);
    memcpy(a + left, tmp + left, (size_t)(right - left) * sizeof(int));
}

static void cilksort(int *a, int n, int sort_threshold, int merge_threshold) {
    int *tmp = malloc((size_t)n * sizeof(int));
    if (!tmp) {
        fprintf(stderr, "Memory allocation error\n");
        exit(EXIT_FAILURE);
    }

    #pragma omp parallel
    {
        #pragma omp single
        cilksort_rec(a, tmp, 0, n, sort_threshold, merge_threshold);
    }

    free(tmp);
}

int main(void) {
    const int N = 10000000;
    const int SORT_THRESHOLD = 64;
    const int MERGE_THRESHOLD = 1024;

    int *a = malloc((size_t)N * sizeof(int));
    if (!a) {
        fprintf(stderr, "Memory allocation error\n");
        return EXIT_FAILURE;
    }
    for (int i = 0; i < N; i++) {
        a[i] = rand();
    }

    double start_time = omp_get_wtime();
    cilksort(a, N, SORT_THRESHOLD, MERGE_THRESHOLD);
    double end_time = omp_get_wtime();

    for (int i = 1; i < N; i++) {
        if (a[i - 1] > a[i]) {
            fprintf(stderr, "Error at %d\n", i);
            break;
        }
    }
    printf(
        "cilk sort completed (sort_threshold=%d, merge_threshold=%d)\n",
        SORT_THRESHOLD, MERGE_THRESHOLD
    );
    printf("Time: %f s\n", end_time - start_time);
    free(a);
    return 0;
}
