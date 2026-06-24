CC := gcc
CFLAGS := -Wall -Wextra -fopenmp
SIMD_CFLAGS := -O1 -DSIMD
BIN_DIR := bin

.PHONY: all clean bench-simd
all: $(BIN_DIR)/simd $(BIN_DIR)/simd_scalar

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/simd: simd.c | $(BIN_DIR)
	$(CC) $(CFLAGS) $(SIMD_CFLAGS) $< -o $@

$(BIN_DIR)/simd_scalar: simd.c | $(BIN_DIR)
	$(CC) $(CFLAGS) -O1 $< -o $@

.PHONY: simd simd_scalar
simd: $(BIN_DIR)/simd
simd_scalar: $(BIN_DIR)/simd_scalar

bench-simd: simd simd_scalar
	python3 bench_simd.py

clean:
	rm -f $(BIN_DIR)/simd $(BIN_DIR)/simd_scalar simd simd_scalar
