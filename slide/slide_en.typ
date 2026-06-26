#import "theme.typ": *
#show: apply-my-theme

#let INFO = (
  title: [OpenMP Tutorial],
  author: [Yuki Maeda],
  date: [2026.06.26],
  institution: [Taura Lab, M1],
  event: [Taura-Lab Spring Training 2026],
)

#show: my-deck-theme(INFO)
#my-cover-slide(INFO)

#slide(title: [Goals of This Tutorial])[
  - Understand the concepts of OpenMP
  - Learn the basics of using OpenMP
  - Learn more generally what to keep in mind in parallel programming
]

= What is OpenMP?

#slide(title: [Basic Architecture of HPC Systems])[
  #set text(size: 0.85em)
  - In HPC, compute clusters formed by connecting many machines over a network are commonly used
  - Each machine in a cluster is called a #text(weight: "bold")[node]
  - Each node has a CPU, memory, and sometimes a GPU
    - A CPU contains multiple #text(weight: "bold")[cores] that can execute multiple operations in parallel
  - Within one node, multiple cores share memory (*shared memory*)
  - Across nodes, memory is not shared (*distributed memory*)
  #align(center)[
    #image("img/hpc_cluster.svg", width: auto, height: 55%)
  ]
]

#slide(title: [What is OpenMP?])[
- *OpenMP* is an API specification and standard for parallelizing programs on shared-memory parallel computers
	- MP stands for Multi-Processing
	- Available from C, C++, and Fortran
- Advantage: parallel processing can be written easily using compiler directives such as `#pragma omp parallel`
	- #text(weight: "bold")[Parallelization can be added easily with minimal changes to existing sequential code]
- Example: parallelizing a for loop
  #align(center)[
    #grid(
      columns: (1fr, 0.2fr, 1.5fr),
      gutter: 1em,
      [
        #align(right)[
          ```c
          for (int i=0; i<N; i++) {
            a[i] = i;
          }
          ```
        ]  
      ],
      [
        #text(fill: accent, size: 2em)[➡︎]
      ],
      [
        #align(left)[
          ```c
          [[[#pragma omp parallel for]]]
          for (int i=0; i<N; i++) {
            a[i] = i;
          }
          ```
        ]
      ]
    )
  ]
]

#slide(title: [[Note] What Does "API Specification / Standard" Mean?])[
- OpenMP is not the name of a single library, but a #text(weight: "bold")[specification] for parallelization
- The specification includes the following:
  - Compiler directives such as `#pragma omp ...`
  - Runtime functions such as `omp_get_thread_num()`
  - Environment variables such as `OMP_NUM_THREADS`
- In practice, compilers and runtimes implement this specification
  - GCC: `libgomp`
  - LLVM/Clang: `libomp`
  - Intel oneAPI: Intel OpenMP runtime
- OpenMP specification: https://www.openmp.org/specifications/
]

#slide(title: [[Note] What is pragma?])[
  - A pragma is a directive to the compiler (*directive*)
  - In C/C++, it is written as a line starting with *`#pragma`*
  - In OpenMP, parallelization instructions are given to the compiler in the form *`#pragma omp ...`*
  - OpenMP uses pragmas so that parallelization directives can be added to existing C/C++/Fortran programs without significantly changing the original code structure
]

#slide(title: [Intra-node and Inter-node Parallelization])[
- OpenMP handles intra-node parallelization (#text(weight: "bold")[shared-memory parallelization])
- APIs such as *MPI* handle inter-node parallelization (#text(weight: "bold")[distributed-memory parallelization])
- In real HPC, #text(weight: "bold")[hybrid parallelism] using MPI across nodes and OpenMP within nodes is important
  - OpenMP alone is mainly limited to a single node; MPI is needed to scale out for large computations
  - On the other hand, distributed memory requires attention to communication, data placement, and load balancing, and achieving good performance is not easy
]


#slide(title: [`#pragma omp parallel`])[
  - A basic directive for creating a #text(weight: "bold")[parallel region] executed by multiple threads
  - Written as below, each thread executes the statements in the parallel region
  - Note that #text(weight: "bold")[the same statements are executed once per thread]
  - Threads synchronize at the end of the block (*fork-join model*)
  ```c
  // sequential region

  [[[#pragma omp parallel]]]
  { 
    // parallel region
  }

  // sequential region
  ```
]


#slide(title: [Fork-Join Model])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    [
      #image("img/fork_join_model.png", width: auto, height: auto, fit: "contain")
    ],
    [
      - Upon entering the parallel region, execution forks into multiple threads (*fork*)
      - Each thread executes its work in parallel
      - Threads synchronize at the end of the parallel region (*join*)
    ]
  )
  #align(right)[
    #text(size: 0.7em, fill: rgb("#666"))[
      Source: #link("https://parallelcomputingsite.wordpress.com/2017/04/17/fork-join-in-open-mp/")[
        https://parallelcomputingsite.wordpress.com/2017/04/17/fork-join-in-open-mp/
      ]
    ]
  ]
]

#slide(title: [Sample Program: `hello.c`])[
  ```c
  printf("Before parallel region\n");
  #pragma omp parallel
  {
    int tid = [[[omp_get_thread_num()]]];
    int nthreads = [[[omp_get_num_threads()]]];
    printf("Hello, World! I'm thread %d of %d\n", tid, nthreads);
  }
  printf("After parallel region\n");
  ```
  - Written this way, all threads execute the statements inside `{ }`
  - *`omp_get_num_threads()`* returns the total number of threads
  - *`omp_get_thread_num()`* returns this thread's ID
]

#slide(title: [Let's Try Compiling])[
  - To use OpenMP, pass `-fopenmp` at compile time
  ```sh
  $ gcc [[[-fopenmp]]] hello.c -o hello
  $ clang [[[-fopenmp]]] hello.c -o hello
  ```
  - However, with clang, an OpenMP runtime may be required separately
  - Note: on macOS this gets complicated
    - On macOS, `gcc` is only named gcc; it is actually Apple Clang
    - In that case, you cannot compile as shown above
    - The easiest approach is to install gcc via Homebrew
    ```sh
    $ brew install gcc
    $ gcc-<your_gcc_version> -fopenmp hello.c -o hello
    ```
    - For the sample programs, change the Makefile to `CC := gcc-<your_gcc_version>`
]

#slide(title: [[Note] What is Apple Clang?])[
  - On macOS, run the following:
  ```sh
  $ gcc --version
  Apple clang version 17.0.0 (clang-1700.6.3.2)
  Target: arm64-apple-darwin25.1.0
  Thread model: posix
  InstalledDir: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
  ```
  - Apple Clang does not directly support `-fopenmp`
  - It is still possible to make Apple Clang work
  ```sh
  $ brew install libomp
  $ clang -Xpreprocessor -fopenmp -lomp \
  -I$(brew --prefix libomp)/include \
  -L$(brew --prefix libomp)/lib \
  hello.c -o hello
  ```
]

#slide(title: [Let's Try Running])[
  - At runtime, you can specify the number of threads as follows:
  ```sh
  $ OMP_NUM_THREADS=4 ./hello
  ```
  - Alternatively, you can set it as an environment variable in advance
  ```sh
  $ export OMP_NUM_THREADS=4
  $ ./hello
  ```
  - You can also set it in the program with `omp_set_num_threads(num_threads)`
]

#slide(title: [Execution Results])[
  - Example output:
  ```bash
  $ OMP_NUM_THREADS=4 ./hello
  Before parallel region
  Hello, World! I'm thread 1 of 4
  Hello, World! I'm thread 2 of 4
  Hello, World! I'm thread 0 of 4
  Hello, World! I'm thread 3 of 4
  After parallel region
  ```
  - Indeed, each thread executes the statements inside the parallel region
  - The order `Before` → `Hello` → `After` is always preserved
    - This is due to the fork-join model
    - The order within `Hello` may change on each run
]

#slide(title: [In Practice?])[
  #set text(size: 0.85em)
  - In practice, we want threads to share different work, not just execute the same code
  - In OpenMP, `parallel` creates a team of threads, and constructs inside it split and distribute work
  - Representative constructs:
    - *for construct*: `#pragma omp for`#linebreak()splits loop iterations
    - *sections construct*: `#pragma omp sections`#linebreak()runs multiple independent blocks in parallel
    - *task construct*: `#pragma omp task`#linebreak()dynamically creates tasks for flexible distribution
  - Note that `for` and `sections` also have combined short forms with `parallel`
    - `#pragma omp parallel for`
    - `#pragma omp parallel sections`
  - `task` is usually created from `single` inside a `parallel` region
]

= Loop Parallelization

#slide(title: [for Construct])[
  #set text(size: 0.9em)
  #grid(
    columns: (0.7fr, 0.3fr),
    gutter: 1em,
    [
      - Written as below, each iteration of the for loop is distributed to threads

      ```c
      [[[#pragma omp parallel]]]
      {
        [[[#pragma omp for]]]
        for (int i = 0; i < N; i++) {
          a[i] = i;
        }
      }
      ```

      - Can be abbreviated as follows

      ```c
      [[[#pragma omp parallel for]]]
      for (int i = 0; i < N; i++) {
        a[i] = i;
      }
      ```
    ],
    [
      #image("img/101.png", width: 100%, height: 90%, fit: "contain")
    ],
  )

  #align(right)[
    #text(size: 0.7em, fill: rgb("#666"))[
      Source: #link("https://www.geeksforgeeks.org/c/c-parallel-for-loop-in-openmp/")[
        https://www.geeksforgeeks.org/c/c-parallel-for-loop-in-openmp/
      ]
    ]
  ]
]


#slide(title: [Let's Run `parallel_for.c`])[
  - Let's run `parallel_for.c`
  - Example output:
  ```bash
  $ OMP_NUM_THREADS=4 ./parallel_for
  Loop 2 is being processed by thread 1
  Loop 3 is being processed by thread 1
  Loop 4 is being processed by thread 2
  Loop 5 is being processed by thread 2
  Loop 0 is being processed by thread 0
  Loop 1 is being processed by thread 0
  Loop 6 is being processed by thread 3
  Loop 7 is being processed by thread 3
  ```
  - Loops are assigned to each thread in blocks of $frac(#jp[number of iterations], #jp[number of threads])$ starting from the lowest index
  - This assignment method can be changed (discussed later)
]

= For Correct Parallelization <touying:skip>

== Shared and Private Variables

#slide(title: [Caution ①: Shared and Private Variables])[
  - In OpenMP, variables are either shared across threads (*shared variables*) or allocated independently per thread (*private variables*)
    - This is called a variable's *attribute*
  - Except for the loop variable immediately after `#pragma omp parallel for`, all variables are shared(!)
  - That is, a program like the following does not work correctly
    - `j` is a shared variable
    - Between `j = i` and `a[j] = i`, `j` may be overwritten by another thread
  ```c
  int i, j;
  #pragma omp parallel for
  for (i = 0; i < N; i++) {
    j = i;
    a[j] = 1;
  }
  ```
]

#slide(title: [Caution ①: Shared and Private Variables])[
  #set text(size: 0.9em)
  - Let's confirm that something actually goes wrong
  ```c
  #pragma omp parallel for
  for (i = 0; i < 10000; i++) {
      j = i;
      a[j] = 1;
  }

  long sum = 0;
  for (int idx = 0; idx < 10000; idx++) sum += a[idx];
  ```
  - Output of `attribution_err.c`
    - The correct result is `Sum = 10000`
  ```bash
  $ OMP_NUM_THREADS=4 ./attribution_err
  Sum = 9986
  $ OMP_NUM_THREADS=4 ./attribution_err
  Sum = 9989
  $ OMP_NUM_THREADS=1 ./attribution_err
  Sum = 10000
  ```
]

#slide(title: [Caution ①: Shared and Private Variables])[
  #set text(size: 0.9em)
  - The correct approach: use a `private` clause to make variables private
  ```c
  int i, j;
  #pragma omp parallel for [[[private(j)]]]
  for (i = 0; i < N; i++) {
    j = i;
    a[j] = 1;
  }
  ```
  - Alternatively, `default(private)` makes private the default
  - Or, in this case, this also works
    - Variables declared inside the parallel region should be private
  ```c
  int i;
  #pragma omp parallel for
  for (i = 0; i < N; i++) {
    [[[int j = i;]]]
    a[j] = 1;
  }
  ```
]


#slide(title: [[Note] Variable Attributes])[
  - *private*: each thread gets its own copy; #text(weight: "bold")[the value at parallel region entry is undefined]
  - *shared*: all threads refer to the same variable; conflicts require synchronization to avoid undefined behavior
  - *firstprivate*: like private, but #text(weight: "bold")[initialized from the parent thread's value at parallel region entry]
  - *lastprivate*: after the parallel region, the value from the last-updating thread is copied back to the parent thread
  - See `attribution.c` for details
]

== Examples That Cannot Be Parallelized

#slide(title: [Caution ②: Examples That Cannot Be Parallelized])[
  - Not every for loop can be parallelized
  - Programs with *flow dependence*—where results differ unless `i` runs from `1` to `N` in order—are difficult to parallelize (unless the algorithm is changed)
  - Example 1:
    ```c
    for (i = 1; i < N - 1; i++) {
      a[i] = a[i] + 1;
      b[i] = a[i - 1] + a[i + 1];
    }
    ```
    - `a[i - 1]` may not have been updated yet
]

#slide(title: [Caution ②: Examples That Cannot Be Parallelized])[
  - Example 2:
    ```c
    for (i = 0; i < N; i++) {
      a[i] = a[b[i]];
    }
    ```
    - Whether parallelization is possible depends on the contents of `b[i]`
]

== Data Races

#slide(title: [Caution ③: Data Races])[
  - Handling *data races* is important in parallel processing
  - Example: estimating $pi$ with Monte Carlo
    - For each trial `i`, compute `trial_hits(i)` (throw arrows randomly `SUBSAMPLES` times) and add hits to the shared variable `hits`
  - Below is an example that causes a data race
  ```c
  long long hits = 0;

  #pragma omp parallel for
  for (int i = 0; i < N; i++) {
    long long h = trial_hits(i);
    hits += h;  // data race!
  }
  ```
  - Another thread may write to `hits` between the read and write
  - OpenMP provides several ways to avoid data races
]

#slide(title: [Avoiding Data Races ①: lock])[
  - OpenMP provides lock mechanisms
  - For the previous example:
  ```c
  [[[omp_lock_t lock;]]]
  [[[omp_init_lock(&lock);]]]
  #pragma omp parallel for
  for (int i = 0; i < N; i++) {
    long long h = trial_hits(i);
    [[[omp_set_lock(&lock);]]]
    hits += h;
    [[[omp_unset_lock(&lock);]]]
  }
  ```
]

#slide(title: [Avoiding Data Races ②: critical Directive])[
  #set text(size: 0.9em)
  - Statements inside `#pragma omp critical` are executed by at most one thread at a time
  - Less flexible than locks, but simpler to implement
  - Adding the optional *`(name)`* allows multiple critical sections
	  - Critical sections with the same `name` exclude each other; different `name`s can run concurrently
	  - `name` is optional
  - For the previous example:
  ```c
  #pragma omp parallel for
  for (int i = 0; i < N; i++) {
    long long h = trial_hits(i);
    [[[#pragma omp critical]]]
    {
      hits += h;
    }
  }
  ```
]

#slide(title: [Avoiding Data Races ③: atomic Directive])[
  - For #text(weight: "bold")[a single simple expression] (such as `x+=value` or `x^=value`), `#pragma omp atomic` is faster
  - It updates values efficiently using hardware atomic instructions
  - For the previous example:
  ```c
  #pragma omp parallel for
  for (int i = 0; i < N; i++) {
    long long h = trial_hits(i);
    [[[#pragma omp atomic]]]
    hits += h;
  }
  ```
]

#slide(title: [Let's Compare])[
  - Let's compare the execution times
    - Execution time can be measured with *`omp_get_wtime()`*
  - Run `seq.c`, `lock.c`, `critical.c`, and `atomic.c`
    - `N = 20000000`，`SUBSAMPLES = 16`
  - Example output:
  ```bash
  $ ./seq
  Elapsed time: 1.890952 seconds
  $ ./lock
  Elapsed time: 5.342480 seconds
  $ ./critical
  Elapsed time: 5.382293 seconds
  $ ./atomic
  Elapsed time: 1.273485 seconds
  ```
]

#slide(title: [reduction Clause])[
  #set text(size: 0.9em)
  - For combining results from multiple threads (e.g., a sum), a *reduction* clause is natural
  - In the previous example, the addition to `hits` can be written as:

  ```c
  long long hits = 0;

  #pragma omp parallel for [[[reduction(+:hits)]]]
  for (int i = 0; i < N; i++) {
    long long h = trial_hits(i);
    hits += h;
  }
  ```
  - With `reduction(+:hits)`, each thread has its own private `hits`
  - At the end of the parallel loop, each thread's `hits` is summed into the original `hits`
  - Therefore, the shared variable does not need to be updated on every iteration
    - Unlike `atomic`, it avoids updating the shared variable every time, so it tends to be faster
]

#slide(title: [Conceptual View of reduction])[
  #set text(size: 0.9em)
  - Conceptually, `reduction` is close to the following:
  ```c
  long long hits_local[MAX_THREADS] = {0};

  #pragma omp parallel
  {
    int tid = omp_get_thread_num();

    #pragma omp for
    for (int i = 0; i < N; i++) {
      long long h = trial_hits(i);
      hits_local[tid] += h;
    }
  }

  long long hits = 0;
  for (int t = 0; t < nthreads; t++) {
    hits += hits_local[t];
  }
  ```
]

#slide(title: [Timing Comparison])[
  - Compare `atomic.c` and `reduction.c` on the same Monte Carlo example
  - Example output
  ```bash
  $ ./atomic
  Elapsed time: 1.273485 seconds
  $ ./reduction
  Elapsed time: 0.340737 seconds
  ```
]

#slide(title: [Note: Results Are Not Always Like This])[
  #set text(size: 0.9em)
  - Parallelization benefits depend on the amount of work in the parallel region
  - Varying `SUBSAMPLES` changes the cost of `trial_hits`
    - When small, each iteration is light, so synchronization on `hits` dominates and the parallel version may be slower than `seq`
    - When large, `trial_hits(i)` dominates and parallelization is more effective
  #align(center)[
    #image("img/subsamples_timing.png", height: 60%)
  ]
]

#slide(title: [[Note] Operations Supported by reduction])[
  #set text(size: 0.8em)
  - reduction supports operations other than `+`
  - In C/C++, `+ * & | ^ && || max min` are available
  - Users can also define reduction operations with `declare reduction`
  ```c
  typedef struct {
    double x; double y;
  } Pair;

  #pragma omp declare reduction( \
    pair_plus : Pair : \
    omp_out.x += omp_in.x, omp_out.y += omp_in.y \
  ) initializer(omp_priv = {0.0, 0.0})

  Pair total = {0.0, 0.0};
  #pragma omp parallel for reduction(pair_plus:total)
  for (int i = 0; i < N; i++) {
    Pair p = compute_pair(i);
    total.x += p.x;
    total.y += p.y;
  }
  ```
]


= For Fast Parallelization <touying:skip>

== Scheduling

#slide(title: [Importance of Scheduling])[
  - Scheduling is important for high performance
  - Even with parallelization, imbalanced load distribution hurts performance
  - Especially with OpenMP's fork-join model, all threads wait for the busiest one

  #align(center)[
    #image("img/load_imbalance.svg", height: 60%, fit: "contain")
  ]
]

#slide(title: [Types of Scheduling])[
  - There are three scheduling types for for loops:
    + *`static`*: statically assign `chunk` iterations per thread
    + *`dynamic`*: dynamically assign `chunk` iterations; idle threads fetch the next chunk
    + *`guided`*: gradually decrease the number of iterations assigned per thread

  - Specified as `#pragma omp parallel for schedule(dynamic, CHUNK_SIZE)`
    - If omitted, the spec does not mandate a default, but major implementations use static
]

#slide(title: [static])[
  #set text(size: 0.9em)
  - *`schedule(static, CHUNK_SIZE)`*
    - Split the loop into chunks of `CHUNK_SIZE` and assign them #text(weight: "bold")[statically] in round-robin starting from thread 0
    - The default when the schedule clause is omitted is static, with `CHUNK_SIZE` = $frac(jp("number of iterations"), jp("number of threads"))$#text(size: 0.8em)[(i.e., this is what you get with no schedule clause)]
    - When `CHUNK_SIZE` $= frac(jp("number of iterations"), jp("number of threads"))$
    #align(center)[
      #image("img/static_example_1.svg", width: 55%, fit: "contain")
    ]
    - When `CHUNK_SIZE` $= 1$
    #align(center)[
      #image("img/static_example_2.svg", width: 55%, fit: "contain")
    ]
]

#slide(title: [dynamic])[
  - *`schedule(dynamic, CHUNK_SIZE)`*
    - Split the loop into chunks of `CHUNK_SIZE` and #text(weight: "bold")[assign the next chunk to whichever thread finishes]
    - Effective when per-iteration cost is unknown until runtime
    - If `CHUNK_SIZE` is omitted, it defaults to 1

  #align(center)[
    #image("img/dynamic_example.svg", width: 60%, fit: "contain")
  ]
]

#slide(title: [guided])[
  - *`schedule(guided, CHUNK_SIZE)`*
    - #text(weight: "bold")[Gradually decrease chunk size while assigning the next work to finishing threads]
    - `CHUNK_SIZE` is the minimum chunk size
    - If $k > 1$ is specified, chunk size decreases exponentially toward $k$, but the final chunk may be smaller than $k$
    - If `CHUNK_SIZE` is omitted, it defaults to 1

  #align(center)[
    #image("img/guided_example.svg", width: 80%, fit: "contain")
  ]
]

#slide(title: [Characteristics of Each Scheduling Type])[
  - Chunk size for dynamic and guided affects performance
    - Small chunk → better load balance but higher overhead
    - Large chunk → worse load balance but lower overhead
  - Assignment overhead
    - dynamic and guided schedule at runtime, so overhead is higher than static
    - #text(weight: "bold")[If you can arrange scheduling so load is balanced in advance,] using static scheduling may be even faster
]

#slide(title: [Scheduling Comparison])[
  - Parallelize only the outer for loop below with OpenMP
    - Later iterations have more work
  - Try all three scheduling types and compare execution time
  - Also record which thread handled which iteration
  ```c
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < i; j++) {
      A[i]++;
    }
  }
  ```
]

#slide(title: [Scheduling Comparison])[
  - Run `static.c`, `dynamic.c`, and `guided.c` (4 threads)

  #align(center)[
    #stack(
      spacing: 0.6em,
      image("img/static_schedule.png", width: 80%, height: 25%, fit: "contain"),
      image("img/dynamic_schedule.png", width: 80%, height: 25%, fit: "contain"),
      image("img/guided_schedule.png", width: 80%, height: 25%, fit: "contain"),
    )
  ]
]

#slide(title: [Scheduling Comparison: Measurement Results])[
  - Example output:
  ```bash
  === OpenMP threads: 4 ===
  static : 0.372155 ± 0.004169 s
  dynamic: 0.586862 ± 0.003830 s
  guided : 0.259611 ± 0.067941 s
  ```
  - Despite good load balance, dynamic is slower than static
    - Scheduling overhead is likely the cause
  - guided is fastest
    - It balances low overhead with good load balance
]

#slide(title: [Changing static Chunk Size])[
  - Setting static `CHUNK_SIZE` to 1 splits more evenly (note the original chunk size was $frac(jp("number of iterations"), jp("number of threads"))$)
  - Let's run it
  ```bash
  === OpenMP threads: 4 ===
  static : 0.264197 ± 0.042221 s
  dynamic: 0.586862 ± 0.003830 s
  guided : 0.259611 ± 0.067941 s
  ```
  - Static assignment might have made static faster than guided, but it was not clearly faster
    - Cache hit rate differences?#linebreak()guided has sequential access early on; static strides by 4
]

#slide(title: [Reference: collapse Directive])[
  - When parallelizing nested loops, you can use the collapse directive
  ```c
  #pragma omp parallel for [[[collapse(2)]]]
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < N; j++) {
      C[i][j] = A[i][j] + B[i][j];
    }
  }
  ```
  - No operations may appear between for loops (must be a pure nested loop)
  - `collapse(n)` treats $n$ nested loops as *one large loop* for parallelization
  - Can be combined with the `schedule` directive
]

#slide(title: [Investigating collapse Behavior])[
  - Run `collapse.c`
  - Visualize which iterations each thread handles, color-coded per thread
  - Results with no `schedule` clause (defaults to `static`):

  #align(center)[
    #image("img/collapse_static.png", width: 100%, height: 70%, fit: "contain")
  ]
]

#slide(title: [Investigating collapse Behavior])[
  - Results with `schedule(dynamic, 1)`:
  #align(center)[
    #image("img/collapse_dynamic.png", width: 100%, height: 75%, fit: "contain")
  ]
  - The nested-loop structure is no longer relevant
]

#slide(title: [When collapse Is Useful])[
  - Collapsing nested loops increases the number of iterations to distribute
  - This may not help much on CPU programs like the above, but *parallelizing for loops on GPUs* is a useful case
  - See the Appendix examples for details
]

== Thread Count Tuning

#slide(title: [What Is the Optimal Thread Count?])[
  - Changing topics: what is the optimal thread count?
  - More threads do not always mean better performance
    - Only up to the #text(weight: "bold")[number of logical cores] can run threads at once
  - Commands to find available logical cores:
    - Linux: `nproc`
    - macOS: `sysctl -n hw.logicalcpu`
  - Miyabi-g has 72 logical cores
]

#slide(title: [Thread Count vs. Runtime ①: Compute-heavy Example])[
  #set text(size: 0.9em)
  - Run `measure_threads_compute.c`, which does heavy per-element work, with varying thread counts
    - With enough work per iteration, strong speedup is expected

  #grid(
    columns: (1fr, 1.5fr),
    gutter: 1em,
    [
      ```c
      WORK = 100
      #pragma omp parallel for
      for (long i = 0; i < N; i++) {
        double x = 1.0 + 1.0e-9 * i;
        for (int k = 0; k < WORK; k++) {
          x = x * 1.0000001 + 0.0000001;
          x = x * 0.9999999 + 0.0000002;
        }
        out[i] = x;
      }
      ```
    ],
    [
      #align(center)[
        #image("img/threads_compute.png", width: auto)
      ]
    ],
  )


  - Speedup grows with thread count but diverges from ideal near the logical core count
]

#slide(title: [Thread Count vs. Runtime ②: Memory Bandwidth Effects])[
  #set text(size: 0.9em)
  - Increasing threads does not always keep improving performance
  - Example: simple operation on large arrays (`measure_threads_mem.c`)
    - This workload is memory-bound relative to compute
    - Reads `B[i]`, `C[i]` and writes `A[i]`
  - With more threads, *memory bandwidth* may saturate before CPU cores

  #grid(
    columns: (1fr, 1.5fr),
    gutter: 1em,
    [
      ```c
      #pragma omp parallel for
      for (long i = 0; i < N; i++) {
        A[i] = B[i] + 2.0 * C[i];
      }
      ```
    ],
    [
      #align(center)[
        #image("img/threads_mem.png", width: auto)
      ]
    ],
  )
]

#slide(title: [Thread Count vs. Runtime ③: Contention Effects])[
  #set text(size: 0.85em)
  - Even with correct synchronization, more threads are not always faster
  - Example: histogram computation (`measure_threads_hist.c`)
  - `atomic` prevents data races
  - However, if many threads frequently update the same `hist[bin]`, that location becomes a bottleneck
  - If data is skewed toward certain bins, contention worsens with more threads

  #grid(
    columns: (1fr, 1.5fr),
    gutter: 1em,
    [
      ```c
      #pragma omp parallel for
      for (int i = 0; i < N; i++) {
        int bin = data[i];
        #pragma omp atomic
        hist[bin]++;
      }
      ```
    ],
    [
      #align(center)[
        #image("img/threads_hist.png", width: auto)
      ]
    ],
  )
]


= Other Constructs

#slide(title: [single Construct])[
  - Used to run code on #text(weight: "bold")[only one thread] inside a parallel region
  - Inside `single`, only one thread executes
  - Which thread runs is unspecified
  - Unless `nowait` is used, #text(weight: "bold")[there is an implicit barrier after `single`]
  - See also `single.c`
  ```c
  #pragma omp parallel
  {
    [[[#pragma omp single]]]
    {
      work();
    }
  }
  ```
]

#slide(title: [masked Construct])[
  - Similar to `single`; only some threads in the team execute
  - Without a clause, #text(weight: "bold")[thread 0 executes]
    - The `filter` clause specifies which threads execute
  - #text(weight: "bold")[There is no implicit barrier afterward]
  - See also `masked.c`
    - The older `master` construct is deprecated; OpenMP 5.1 recommends `masked`

  ```c
  #pragma omp parallel
  {
    [[[#pragma omp masked]]]
    {
      work();
    }
  }
  ```
]

#slide(title: [Non-loop Parallelization ①: sections Construct])[
  - A somewhat more flexible(?) parallelization method than `for`
  - Each section is assigned to a thread
  ```c
  [[[#pragma omp parallel sections]]]
  {
    [[[#pragma omp section]]]
    {
      work1();
    }
    [[[#pragma omp section]]]
    {
      work2();
    }
  }
  ```
  - Details omitted
]


#slide(title: [Non-loop Parallelization ②: task Construct])[
  - A construct for so-called task parallelism
  - So far we mainly distributed `for` loop iterations across threads
  - However, work to parallelize is not always expressible as a `for` loop
    - Recursive divide-and-conquer
    - Tree/graph traversal
    - Work that appears dynamically at runtime
  - The `task` construct allows more flexible parallel units
]


#slide(title: [Non-loop Parallelization ②: task Construct])[
  #set text(size: 0.85em)
  #grid(
    columns: (1.25fr, 1fr),
    gutter: 1em,
    [
      - Example: computing the Fibonacci sequence
      ```c
      int fib(int n) {
        if (n < 2) return n;
        else{
          [[[#pragma omp task]]] shared(x) firstprivate(n)
          x = fib(n - 1);
          [[[#pragma omp task]]] shared(y) firstprivate(n)
          y = fib(n - 2);
          [[[#pragma omp taskwait]]]
          return x + y;
        }
      }

      #pragma omp parallel
      {
        [[[#pragma omp single]]]
        printf("Fibonacci of %d is %d\n", 10, fib(10));
      }
      ```
    ],
    [
      #set text(size: 0.9em)
      - *`task`* creates work that "someone can execute later"
        - Note: `task` does not create new threads
        - Generated tasks are scheduled onto existing threads by the OpenMP runtime
      - *`taskwait`* waits for child tasks to complete
    ]
  )
]

#slide(title: [Non-loop Parallelization ②: task Construct])[
  #set text(size: 0.85em)
  #grid(
    columns: (1.25fr, 1fr),
    gutter: 1em,
    [
      - Example: computing the Fibonacci sequence
      ```c
      int fib(int n) {
        if (n < 2) return n;
        else{
          [[[#pragma omp task]]] shared(x) firstprivate(n)
          x = fib(n - 1);
          [[[#pragma omp task]]] shared(y) firstprivate(n)
          y = fib(n - 2);
          [[[#pragma omp taskwait]]]
          return x + y;
        }
      }

      #pragma omp parallel
      {
        [[[#pragma omp single]]]
        printf("Fibonacci of %d is %d\n", 10, fib(10));
      }
      ```
    ],
    [
      #set text(size: 0.9em)
      - If all threads call `fib(10)`, the same work is duplicated
      - So only one thread creates the initial tasks via `single` or `masked`
      - Idle threads can also execute generated tasks
    ]
  )
]

#slide(title: [Role of taskwait])[
  - `taskwait` waits for child tasks created by the current task
  - In the Fibonacci example, we must wait until `fib(n - 1)` and `fib(n - 2)` finish
  - Without `taskwait`, `x + y` may be returned before `x` and `y` are computed
  ```c
  #pragma omp task shared(x) firstprivate(n)
  x = fib(n - 1);
  #pragma omp task shared(y) firstprivate(n)
  y = fib(n - 2);
  [[[#pragma omp taskwait]]]
  return x + y;
  ```
]

#slide(title: [Visualizing Task Execution])[
  #set text(size: 0.9em)
  - Run `fib_tree.c` and visualize task creation with `animate_fib.py`

  #align(center)[
    #image("img/fibonacci_tasks_animation.gif", width: 80%)
  ]

  - #link("https://github.com/yukim0359/OpenMP-tutorial/blob/main/slide/img/fibonacci_tasks_animation.gif")[Link to GIF]
]

// #slide(title: [Running `fib.c`])[
//   - Run `fib.c`
//   - Example output:
//   ```bash
//   $ ./fib
//   serial version
//   Fibonacci of 50 is 12586269025
//   Elapsed time: 51.424394 seconds

//   $ OMP_NUM_THREADS=4 ./fib
//   OpenMP version
//   threads: 4
//   Fibonacci of 50 is 12586269025
//   Elapsed time: 23.339175 seconds
//   ```
// ]

#slide(title: [[Note] Caveats of the Fibonacci Example])[
  - Fibonacci is easy to explain for illustrating `task`
  - But it is not a good example of practical high-performance optimization
    - There is no real need for task parallelism here
    - Tasks are too fine-grained; creation overhead dominates
    - It does not resemble real task-parallel programs
  - It is often used to measure runtime overhead instead
  - For more realistic task-parallel benchmarks, see #link("https://github.com/bsc-pm/bots")[BOTS]
]

#slide(title: [Controlling Task Granularity])[
  #set text(size: 0.9em)
  - Creating and managing tasks has overhead
    - If tasks are too small, sequential execution is faster than taskifying
  - In practice, a threshold (*cutoff*) like this is common

  ```c
  int fib(int n) {
    [[[if (n < 20) {]]]
      [[[return fib_serial(n);]]]
    [[[}]]]

    int x, y;
    #pragma omp task shared(x) firstprivate(n)
    x = fib(n - 1);
    #pragma omp task shared(y) firstprivate(n)
    y = fib(n - 2);
    #pragma omp taskwait
    return x + y;
  }
  ```
]

#slide(title: [`if` Clause])[
  - OpenMP `task` can take an `if` clause
  - If true, a normal task is created
  - If false, the task is generally executed immediately in place
  - Like a manual cutoff, it avoids creating overly fine tasks
  ```c
  #pragma omp task [[[if(n > 20)]]] shared(x) firstprivate(n)
  x = fib(n - 1);
  #pragma omp task [[[if(n > 20)]]] shared(y) firstprivate(n)
  y = fib(n - 2);
  ```
]

#slide(title: [[Note] Task Parallel Scheduling (1/3)])[
  #set text(size: 0.9em)
  - Task parallelism usually uses *dynamic load balancing* rather than *static* due to irregularity
  - The simplest approach is a shared queue
    - One shared task queue #text(size: 0.75em)[(queue of runnable tasks)]; all workers push/pop tasks
    - High contention on queue access
  #align(center)[
    #image("img/global_queue.pdf", width: auto, height: 60%)
  ] 
]

#slide(title: [[Note] Task Parallel Scheduling (2/3)])[
  #set text(size: 0.9em)
  - A faster dynamic approach is *work stealing*
  - Each worker has its own task queue
    - When its queue is empty, it steals tasks from others
    - Known to #text(weight: "bold")[scale better as worker count grows] by reducing queue contention

  #align(center)[
    #image("img/work_stealing.pdf", width: auto, height: 60%)
  ] 
]

#slide(title: [[Note] Task Parallel Scheduling (3/3)])[
  #set text(size: 0.9em)
  #grid(
    columns: (1.2fr, 1fr),
    gutter: 1em,
    [
      - The OpenMP spec does not fix scheduling policy; it varies by implementation
      - [Unverified] According to ChatGPT:
        - GCC libgomp: shared queue
        - LLVM libomp: work stealing
      - Measure while scaling `OMP_NUM_THREADS` on fib
    ],
    [
      #align(center)[
        #image("img/fib_threads_timing.png", width: 100%)
      ]
    ]
  )

  - LLVM libomp scales well; GCC libgomp slows down with more threads
]

#slide(title: [[Note] task depend])[
  - The `depend` clause specifies dependencies between tasks
  - Dependent work can be expressed as a DAG
    - Tasks run when dependencies are satisfied
    - Enables finer control than plain fork-join synchronization

  #grid(
    columns: (1.8fr, 1fr),
    gutter: 1em,
    [
      ```c
      #pragma omp task [[[depend(out: A)]]]
      compute_A();
      #pragma omp task [[[depend(in: A)]]] [[[depend(out: B)]]]
      compute_B();
      #pragma omp task [[[depend(in: A)]]] [[[depend(out: C)]]]
      compute_C();
      #pragma omp task [[[depend(in: B, C)]]]
      compute_D();
      ```
    ],
    [
      #align(center)[
        #image("img/task_depend_dag.svg", width: 70%, fit: "contain")
      ]
    ]
  )
]

#slide(title: [[Note] Distributed-memory Task Parallel System Itoyori])[
  - OpenMP `task` is task parallelism in shared memory
  - Task parallelism across distributed memory on multiple nodes is not easy
    - Which node runs each task
    - Where to place required data
    - When to communicate across nodes
    - How to balance load
  - Itoyori is one example of a *runtime for task parallelism in distributed memory* (#link("https://dl.acm.org/doi/10.1145/3581784.3607049")[Paper], #link("https://github.com/itoyori/itoyori")[GitHub])
]

#slide(title: [[Note] GPU Task Parallel System GTaP])[
  #set text(size: 0.9em)
  - GTaP is a runtime for task parallelism on GPUs (#link("https://arxiv.org/abs/2604.05982")[Paper], #link("https://github.com/yukim0359/GTaP")[GitHub])
  - A resident GPU runtime manages task creation, execution, and synchronization
    - Schedules tasks on the GPU instead of launching many small kernels from the CPU
    - *`#pragma gtap task`* / *`#pragma gtap taskwait`* allow OpenMP-like syntax
      - Supporting fork-join on GPUs is not trivial
  - Two execution modes:
    - *1 thread 1 task*:
      Run fine-grained irregular tasks on many GPU threads
    - *1 thread block 1 task*:
      When a task has internal data parallelism, threads in one block cooperate
]

= Appendix <touying:skip>

== SIMD

#slide(title: [SIMD Features in OpenMP])[
  - SIMD runs the same instruction on multiple data elements in parallel
  - OpenMP provides SIMD via `#pragma omp simd`
  ```c
  [[[#pragma omp simd]]]
  for (int i = 0; i < N; i++) {
    b[i] = 2 * a[i];
  }
  ```
]

#slide(title: [Reference: Compilation and Optimization Report])[
  - Compile as below to write a vectorization report to `vec_report.txt`
  - `-O3` sets the optimization level
  ```bash
  $ gcc-15 -O3 [[[-fopt-info-vec-optimized=vec_report.txt]]] -fopenmp simd.c -o simd
  ```
  - Example output:
  ```bash
  simd.c:30:21: optimized: loop vectorized using 16 byte vectors
  simd.c:30:21: optimized: loop vectorized using 8 byte vectors
  simd.c:18:10: optimized: loop vectorized using 16 byte vectors
  ```
  - This confirms SIMD vectorization
]

#slide(title: [Reference: Generating Assembly])[
  - Compile as below to emit assembly to `simd.s`
  ```bash
  $ gcc-15 -O1 -fopenmp -S simd.c -o simd.s
  ```
  - Example output:
  ```text
  ldr q31, [x7, x1]           // 128-bit load from address x7 + x1 (four ints)
  add v31.4s, v31.4s, v31.4s  // double each of four 32-bit ints in v31 (vector add)
  str q31, [x0, x1]           // 128-bit store to x0 + x1 (write result)
  ```
  - Data is loaded into vector registers and four integers are doubled at once
  - On Mac, the SIMD extension appears to be #link("https://developer.arm.com/documentation/dht0002/a/Introducing-NEON?lang=en")[Arm Neon]
  - SIMD registers are 128 bits wide, so four 32-bit ints or two 64-bit floats can be processed at once
]

#slide(title: [Runtime Comparison With and Without SIMD])[
  - `make bench-simd` runs each configuration 10 times and shows mean ± std dev
    - At `-O1`, with and without `#pragma omp simd`
    - Confirm SIMD instructions are enabled/disabled in assembly
  - With SIMD:
  ```bash
  $ make bench-simd
  # SIMD (simd), 10 runs each
    OMP_NUM_THREADS=1: 0.032581 ± 0.000935
    OMP_NUM_THREADS=4: 0.015092 ± 0.000373
  ```
  - Without SIMD:
  ```bash
  # scalar (simd_scalar), 10 runs each
    OMP_NUM_THREADS=1: 0.048844 ± 0.001819
    OMP_NUM_THREADS=4: 0.017411 ± 0.000664
  ```
]

#slide(title: [Runtime Comparison With and Without SIMD])[
  #set text(size: 0.9em)
  - Above: mean over 10 runs per configuration; std dev included
  - However, SIMD is not always faster by exactly the vector width
    - Memory access, cache, loop control, and instruction scheduling matter
    - With more threads, memory bandwidth and other factors may bottleneck
  - In this environment/program, at `-O3`, SIMD was enabled even without `#pragma omp simd`
]

== OpenMP GPU Support

#slide(title: [OpenMP Support for GPUs])[
  - Since OpenMP 4.0, features for accelerators such as GPUs were added
  - The `target` directive enables GPU execution
  - A similar accelerator API is *OpenACC*
    - ACC stands for Accelerator
    - Unlike OpenMP, designed specifically for accelerators
]

#slide(title: [Basic Model of OpenMP GPU Offloading])[
  #set text(size: 0.9em)
  ```c
  #pragma omp [[[target teams distribute parallel for \]]]
      [[[map(to: A[0:N], B[0:N]) map(from: C[0:N])]]]
  for (int i = 0; i < N; i++) {
    C[i] = A[i] + B[i];
  }
  ```
  - `target`: execute on the GPU
  - `teams`: create multiple teams on the GPU
  - `distribute`: distribute loop iterations among teams
  - `parallel for`: parallelize the loop within each team
  - `map`: transfer data between host and device
]

#slide(title: [GPU Caveat: Data Transfer Cost])[
  #set text(size: 0.9em)
  - GPU compute may not help if data is transferred every time
    - Transfer input from host to device memory
    - Compute on device
    - Transfer results from device to host memory
  - Many small GPU jobs make transfer/launch overhead dominate compute time
  ```c
  #pragma omp target data map(to: A[0:N], B[0:N]) map(from: C[0:N])
  {
    #pragma omp target teams distribute parallel for
    for (int i = 0; i < N; i++) {
      C[i] = A[i] + B[i];
    }

    // Run multiple GPU kernels here if needed
  }
  ```
]

== Program Examples

#slide(title: [for Parallel Example: Matrix Multiplication])[
  #set text(size: 0.8em)
  - Tuned matrix multiplication with OpenMP `for` parallelism
    - Loop reordering (i-k-j) for sequential access to rows of A and B
    - Blocking (`TILE`) for L1/L2 cache reuse
    - Parallelize the outer loop with `#pragma omp parallel for`
  - See `matmul_tuned.c`
  ```c
  #pragma omp parallel for schedule(static)
  for (int ii = 0; ii < N; ii += TILE) {
    for (int kk = 0; kk < N; kk += TILE) {
      for (int jj = 0; jj < N; jj += TILE) {
        for (int i = ii; i < i_end; i++) {
          for (int k = kk; k < k_end; k++) {
            double a_ik = A[i][k];
            for (int j = jj; j < j_end; j++) {
              C[i][j] += a_ik * B[k][j];
            }
          }
        }
      }
    }
  }
  ```
]

#slide(title: [task Parallel Example: merge sort, cilk sort])[
  - Recursive sort pairs well with OpenMP `task`
    - Split the array and taskify sorting subarrays
    - Sort small subarrays sequentially without tasks
      - e.g., insertion sort, sequential merge sort
    - `taskwait` for children, then merge
  - Simple parallel merge sort:
    - Taskify sorting left and right halves
    - Merge sequentially at the end
  - Cilk sort:
    - *Taskify merge recursively, not just sort*
    - Extracts more parallelism
  - See `parallel_merge_sort.c` and `cilk_sort.c`
]

#slide(title: [GPU Execution Example: Matrix Multiplication])[
  - GPU matrix multiplication in OpenMP
    - Simple, no extra tuning
  - See `matmul_gpu.c`
  ```c
  #pragma omp target data map(to:A[0:N][0:N], B[0:N][0:N]) map(from:C[0:N][0:N])
  {
    #pragma omp target teams distribute parallel for [[[collapse(2)]]]
    for(int i = 0; i < N; i++) {
      for(int j = 0; j < N; j++) {
        for(int k = 0; k < N; k++) {
          C[i][j] += A[i][k] * B[k][j];
        }
      }
    }
  }
  ```
]

#slide(title: [GPU Execution Example: Matrix Multiplication])[
  - Compare runtime with and without `collapse(2)` (on miyabi-g)
  - Example output:

  ```bash
  $ ./matmul_gpu
  Use collapse
  Test passed!
  Computation time: 0.386624 seconds

  $ ./matmul_gpu
  No collapse
  Test passed!
  Computation time: 0.702773 seconds
  ```

  - `collapse` increases iterations from $N$ to $N^2$, spreading work across many GPU threads
]

== Implementation of Directives

#slide(title: [Implementation of Directives])[
  - May contain errors
  - Below we focus only on `libgomp` in gcc
  - See #link("https://github.com/gcc-mirror/gcc/tree/releases/gcc-9.2.0/libgomp")[https://github.com/gcc-mirror/gcc/tree/releases/gcc-9.2.0/libgomp]
]

#slide(title: [Directive Implementation ①: Thread Creation])[
  - The `parallel` directive expands roughly as:
  ```c
  void subfunction (void *data)
  {
    use data;
    body;
  }

  setup data;
  GOMP_parallel_start (subfunction, &data, num_threads);
  subfunction (&data);
  GOMP_parallel_end ();
  ```
  - `GOMP_parallel_start` calls `gomp_team_start()` to create OS threads (Linux, Mac: `pthread_create`)
  - See `parallel.c` and `team.c` in the repo
]

#slide(title: [Directive Implementation ②: lock Implementation])[
  - In my investigation, equivalent to `pthread_mutex`
  - Defined in `config/posix/mutex.h` as:
  ```c
  typedef pthread_mutex_t gomp_mutex_t;
  static inline void gomp_mutex_init (gomp_mutex_t *mutex)
  {
    pthread_mutex_init (mutex, NULL);
  }
  static inline void gomp_mutex_lock (gomp_mutex_t *mutex)
  {
    pthread_mutex_lock (mutex);
  }
  // omitted
  ```
  - See `lock.c`
]

#slide(title: [Directive Implementation ③: critical Implementation])[
  - Unnamed critical section definition
  ```c
  void
  GOMP_critical_start (void)
  {
    /* There is an implicit flush on entry to a critical region. */
    __atomic_thread_fence (MEMMODEL_RELEASE);
    gomp_mutex_lock (&default_lock);
  }

  void
  GOMP_critical_end (void)
  {
    gomp_mutex_unlock (&default_lock);
  }
  ```
  - Apparently managed with a mutex
  - See `critical.c`
]

#slide(title: [Directive Implementation ④: atomic Implementation])[
  - Assembly of `atomic1.c` shows the atomic part as:

  ```text
  ldadd w1, w0, [x0]
  ```

  - On ARM, `ldadd` atomically loads from `[x0]`, adds `w0`, stores to `[x0]`, and returns the old value in `w1`
]

#slide(title: [Directive Implementation ④: atomic Implementation])[
  #set text(size: 0.9em)
  - What about a more complex case?
  - Assembly of `atomic2.c` shows:

  ```text
  LFB0:
      fadd    d0, d0, d0     // double b
      ldr     x1, [x0]       // load *a into x1
  L2:
      fmov    d31, x1        // move x1 to FP register d31
      mov     x2, x1         // copy x1 to x2
      fadd    d31, d0, d31   // d31 = *a + 2*b
      fmov    x3, d31        // store new value in x3
      cas     x2, x3, [x0]   // if [x0] still equals x2 (old), atomically write x3 (new)
                             // in any case, old memory value returned in x2
      cmp     x1, x2         // if x1==x2 after cas, success
      bne     L3             // retry on failure
      ret
  ```

  - This is a CAS loop
]
