# OpenMP Tutorial

## Folder Structure

- `01_openmp/` - Basic usage of OpenMP
- `02_loop/` - Loop parallelization
- `03_correct_parallel/` - Correct parallelization (`shared_private/`, `data_race/`)
- `04_fast_parallel/` - Performance tuning (`scheduling/`, `threads/`)
- `05_other_syntax/` - Other directives (`single`, `masked`, `task/`)
- `06_appendix/` - Additional materials and examples (`simd/`, `examples/`, `implementation/`)
- `slide/` - Slides

## Build Instructions

In each directory, or in its parent directory, run the following command:

```bash
make
```

## How to Run

After building, execute the generated binary file:

```bash
./[executable_name]
```

If you want to specify the number of threads:

```bash
OMP_NUM_THREADS=8 ./[executable_name]
```

## Notes

- Slide materials are in the `slide/` directory.
- Each directory contains sample code related to its topic.
- Additional examples and materials can be found in the `06_appendix/` directory.
