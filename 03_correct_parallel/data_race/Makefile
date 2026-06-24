CC := gcc
CFLAGS := -Wall -Wextra -fopenmp

N ?= 20000000
SEED ?= 42
SUBSAMPLES ?= 16
SUM_CFLAGS := -DN=$(N) -DSEED=$(SEED) -DSUBSAMPLES=$(SUBSAMPLES)

SUM_PROGS := seq lock atomic critical reduction
BIN_DIR := bin
BIN_SUM_PROGS := $(addprefix $(BIN_DIR)/,$(SUM_PROGS))

all: $(BIN_SUM_PROGS)

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/%: %.c monte_carlo_pi.h | $(BIN_DIR)
	$(CC) $(CFLAGS) $(SUM_CFLAGS) $< -o $@

VENV := .venv
PY := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
CSV_DIR := csv
IMG_DIR := img

.PHONY: clean plot-venv plot-subsamples outdirs $(SUM_PROGS)

outdirs: csv img

csv:
	@mkdir -p $(CSV_DIR)

img:
	@mkdir -p $(IMG_DIR)

$(SUM_PROGS): %: $(BIN_DIR)/%

clean:
	rm -f $(BIN_SUM_PROGS) $(SUM_PROGS)

$(PY): requirements-plot.txt
	python3 -m venv $(VENV)
	$(PIP) install matplotlib

plot-venv: $(PY)
	@echo "venv ready: $(PY)"

plot-subsamples: $(PY) outdirs
	$(PY) plot_subsamples.py
