CC := gcc
CFLAGS := -Wall -Wextra -fopenmp

CSV_DIR := csv
IMG_DIR := img
C_EXECUTABLES := $(patsubst %.c,%,$(wildcard *.c))
BIN_DIR := bin
BIN_EXECUTABLES := $(addprefix $(BIN_DIR)/,$(C_EXECUTABLES))

all: outdirs $(BIN_EXECUTABLES)

outdirs: csv img

csv:
	@mkdir -p $(CSV_DIR)

img:
	@mkdir -p $(IMG_DIR)

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/%: %.c | outdirs $(BIN_DIR)
	$(CC) $(CFLAGS) $< -o $@

.PHONY: clean $(C_EXECUTABLES)
$(C_EXECUTABLES): %: $(BIN_DIR)/%

clean:
	rm -f $(BIN_EXECUTABLES) $(C_EXECUTABLES)
