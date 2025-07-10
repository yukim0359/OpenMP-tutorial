#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

static int  id_counter = 0;
omp_lock_t  id_lock;
FILE       *dot_fp;
double      start_time;
const char* thread_colors[] = {
    "lightblue", "lightgreen", "lightpink", "lightgoldenrod",
    "lightcyan", "lightcoral", "lightseagreen", "lightgoldenrod1"
};
const int  n_colors = sizeof(thread_colors)/sizeof(thread_colors[0]);

long fib(int n, int parent_id) {
    int my_start_id, my_end_id;
    double t0, t1;
    long result;

    t0 = omp_get_wtime() - start_time;

    omp_set_lock(&id_lock);
    my_start_id = ++id_counter;
    omp_unset_lock(&id_lock);

    if (n < 2) {
        result = n;
    } else {
        long x, y;
        #pragma omp task shared(x)
        x = fib(n - 1, my_start_id);
        #pragma omp task shared(y)
        y = fib(n - 2, my_start_id);
        #pragma omp taskwait
        result = x + y;
    }

    omp_set_lock(&id_lock);
    my_end_id = ++id_counter;
    omp_unset_lock(&id_lock);

    t1 = omp_get_wtime() - start_time;

    #pragma omp critical
    {
        int tid = omp_get_thread_num();
        const char* color = thread_colors[tid % n_colors];
        fprintf(dot_fp,
            "  %d [label=\"fib(%d)\\n(tid=%d)\\n[seq=%d→%d]\\n(%f→%f s)\", style=\"rounded,filled\", fillcolor=%s];\n",
            my_start_id, n, tid, my_start_id, my_end_id, t0, t1, color
        );
        if (parent_id > 0) {
            fprintf(dot_fp, "  %d -> %d;\n", parent_id, my_start_id);
        }
    }

    return result;
}

int main(int argc, char *argv[]) {
    int n = (argc > 1) ? atoi(argv[1]) : 6;

    omp_init_lock(&id_lock);

    dot_fp = fopen("fib_tree.dot", "w");
    if (!dot_fp) {
        perror("fopen");
        return 1;
    }
    fprintf(dot_fp,
        "digraph FibonacciTasks {\n"
        "  node [shape=box];\n"
    );

    start_time = omp_get_wtime();

    #pragma omp parallel
    {
        #pragma omp master
        printf("fib(%d) = %ld\n", n, fib(n, 0));
    }

    fprintf(dot_fp, "}\n");
    fclose(dot_fp);
    omp_destroy_lock(&id_lock);
    return 0;
}
