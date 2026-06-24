CC := gcc
CFLAGS := -Wall -Wextra -fopenmp

C_EXECUTABLES := $(patsubst %.c,%,$(wildcard *.c))
BIN_DIR := bin
BIN_EXECUTABLES := $(addprefix $(BIN_DIR)/,$(C_EXECUTABLES))

all: $(BIN_EXECUTABLES)

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/%: %.c | $(BIN_DIR)
	$(CC) $(CFLAGS) $< -o $@

.PHONY: clean $(C_EXECUTABLES)
$(C_EXECUTABLES): %: $(BIN_DIR)/%

clean:
	rm -f $(BIN_EXECUTABLES) $(C_EXECUTABLES)
