#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <omp.h>

#define N 50
#define DYNAMIC_SCHEDULE

int main() {
    int i, j;
    static int thread_ids[N][N];

#ifdef DYNAMIC_SCHEDULE
    #pragma omp parallel for collapse(2) private(i,j) schedule(dynamic, 1)
#else
    #pragma omp parallel for collapse(2) private(i,j)
#endif
    for (i = 0; i < N; i++) {
        for (j = 0; j < N; j++) {
            thread_ids[i][j] = omp_get_thread_num();
        }
    }

    FILE *fp = fopen("collapse_data.csv", "w");
    if (!fp) {
        perror("fopen");
        return EXIT_FAILURE;
    }
    fprintf(fp, "outer_it,inner_it,thread\n");
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            fprintf(fp, "%d,%d,%d\n",
                    i, j, thread_ids[i][j]);
        }
    }
    fclose(fp);
    return 0;
}
