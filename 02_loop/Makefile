CC := gcc
CFLAGS := -Wall -Wextra -fopenmp
BIN_DIR := bin

all: $(BIN_DIR)/parallel_for

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/parallel_for: parallel_for.c | $(BIN_DIR)
	$(CC) $(CFLAGS) $< -o $@

.PHONY: clean parallel_for
parallel_for: $(BIN_DIR)/parallel_for

clean:
	rm -f $(BIN_DIR)/parallel_for parallel_for
