CC := gcc
CFLAGS := -Wall -Wextra -fopenmp
BIN_DIR := bin
PROGRAMS := single masked
BIN_PROGRAMS := $(addprefix $(BIN_DIR)/,$(PROGRAMS))

all: $(BIN_PROGRAMS)

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/%: %.c | $(BIN_DIR)
	$(CC) $(CFLAGS) $< -o $@

.PHONY: clean task $(PROGRAMS)
$(PROGRAMS): %: $(BIN_DIR)/%

clean:
	rm -f $(BIN_PROGRAMS) $(PROGRAMS)

task:
	$(MAKE) -C task
