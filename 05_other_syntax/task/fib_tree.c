#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

static int  id_counter = 0;
static int  seq_counter = 0;
omp_lock_t  id_lock;
FILE       *dot_fp;
const char* thread_colors[] = {
    "lightblue", "lightgreen", "lightpink", "lightgoldenrod",
    "lightcyan", "lightcoral", "lightseagreen", "lightgoldenrod1"
};
const int  n_colors = sizeof(thread_colors)/sizeof(thread_colors[0]);

long fib(int n, int parent_id) {
    int my_id;
    int start_seq;
    long result;

    omp_set_lock(&id_lock);
    my_id = ++id_counter;
    start_seq = ++seq_counter;
    omp_unset_lock(&id_lock);

    if (n < 2) {
        result = n;
    } else {
        long x, y;
        #pragma omp task shared(x)
        x = fib(n - 1, my_id);
        #pragma omp task shared(y)
        y = fib(n - 2, my_id);
        #pragma omp taskwait
        result = x + y;
    }

    #pragma omp critical
    {
        int tid = omp_get_thread_num();
        int end_seq = ++seq_counter;
        const char* color = thread_colors[tid % n_colors];

        fprintf(dot_fp,
            "  %d [label=\"fib(%d)\\n(tid=%d)\", start_seq=%d, end_seq=%d, style=\"rounded,filled\", fillcolor=%s];\n",
            my_id, n, tid, start_seq, end_seq, color
        );
        if (parent_id > 0) {
            fprintf(dot_fp, "  %d -> %d;\n", parent_id, my_id);
        }
    }

    return result;
}

int main(int argc, char *argv[]) {
    int n = (argc > 1) ? atoi(argv[1]) : 6;

    omp_init_lock(&id_lock);

    dot_fp = fopen("fib_tree.dot", "w");
    if (!dot_fp) {
        perror("fopen fib_tree.dot");
        return 1;
    }

    fprintf(dot_fp,
        "digraph FibonacciTasks {\n"
        "  graph [fontname=\"Helvetica\", fontsize=16, dpi=144];\n"
        "  node [shape=box, fontname=\"Helvetica\", fontsize=14];\n"
    );

    #pragma omp parallel
    {
        #pragma omp master
        printf("fib(%d) = %ld\n", n, fib(n, 0));
    }

    fprintf(dot_fp, "}\n");
    fclose(dot_fp);

    printf("Wrote fib_tree.dot (seq_counter=%d)\n", seq_counter);
    omp_destroy_lock(&id_lock);
    return 0;
}
