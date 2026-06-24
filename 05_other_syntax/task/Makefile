CFLAGS_COMMON := -Wall -Wextra -O3
N ?= 32
CUTOFF ?= -1
OMP_NUM_THREADS ?= $(shell sysctl -n hw.ncpu 2>/dev/null || echo 4)
BIN_DIR := bin

LIBOMP_PREFIX := /opt/homebrew/opt/libomp
CLANG_OMP_CFLAGS := -Xpreprocessor -fopenmp -I$(LIBOMP_PREFIX)/include
CLANG_OMP_LDFLAGS := -L$(LIBOMP_PREFIX)/lib -lomp

VENV := .venv
PY := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
CSV_DIR := csv
IMG_DIR := img
SLIDE_IMG := ../../slide/img

.PHONY: all clean compare fib-gcc fib-clang fib-tree fib-tree-run fib-tree-gif plot-venv plot-fib-threads outdirs

outdirs: csv img

csv:
	@mkdir -p $(CSV_DIR)

img:
	@mkdir -p $(IMG_DIR)

all: fib-gcc fib-clang

$(BIN_DIR):
	mkdir -p $@

fib-tree: $(BIN_DIR)/fib_tree

$(BIN_DIR)/fib_tree: fib_tree.c | $(BIN_DIR)
	clang $(CFLAGS_COMMON) $(CLANG_OMP_CFLAGS) $< -o $@ $(CLANG_OMP_LDFLAGS)

fib-tree-run: fib-tree
	OMP_NUM_THREADS=$(OMP_NUM_THREADS) ./$(BIN_DIR)/fib_tree 6

fib-tree-gif: fib-tree-run plot-venv outdirs
	$(PY) animate_fib.py

fib-gcc: $(BIN_DIR)/fib-gcc

$(BIN_DIR)/fib-gcc: fib.c | $(BIN_DIR)
	gcc-15 $(CFLAGS_COMMON) -fopenmp -DN=$(N) -DCUTOFF=$(CUTOFF) $< -o $@

fib-clang: $(BIN_DIR)/fib-clang

$(BIN_DIR)/fib-clang: fib.c | $(BIN_DIR)
	clang $(CFLAGS_COMMON) $(CLANG_OMP_CFLAGS) -DN=$(N) -DCUTOFF=$(CUTOFF) $< -o $@ $(CLANG_OMP_LDFLAGS)

compare: fib-gcc fib-clang
	@echo "N=$(N), CUTOFF=$(CUTOFF), OMP_NUM_THREADS=$(OMP_NUM_THREADS)"
	@echo "=== gcc-15 (Homebrew) ==="
	@OMP_NUM_THREADS=$(OMP_NUM_THREADS) ./$(BIN_DIR)/fib-gcc
	@echo
	@echo "=== Apple clang + libomp ==="
	@OMP_NUM_THREADS=$(OMP_NUM_THREADS) ./$(BIN_DIR)/fib-clang

$(PY): requirements-plot.txt
	python3 -m venv $(VENV)
	$(PIP) install -r requirements-plot.txt

plot-venv: $(PY)
	@echo "venv ready: $(PY)"

plot-fib-threads: $(PY) outdirs
	$(PY) plot_fib_threads.py --n $(N) --cutoff $(CUTOFF)

clean:
	rm -f $(BIN_DIR)/fib-gcc $(BIN_DIR)/fib-clang $(BIN_DIR)/fib_tree
	rm -f fib-gcc fib-clang fib fib_tree
	rm -f fib_tree.dot
