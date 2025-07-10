# OpenMP Tutorial

## Folder Structure

- `01_tutorial/` - Basic usage of OpenMP
- `02_syntax/` - About OpenMP syntax
- `03_scheduling/` - Types of scheduling and how to use them
- `04_task/` - Task-based parallelization
- `05_attribution/` - Variable attributes
- `06_thread/` - Controlling the number of threads
- `07_appendix/` - Additional materials and examples
- `slide/` - Slides

## Build Instructions

In each directory, or in its parent directory, run the following command:

```bash
make
```

Tested with gcc15.

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
- Additional examples and materials can be found in the `07_appendix/` directory.
