CC := gcc
CFLAGS := -Wall -Wextra -fopenmp

C_SOURCES := $(wildcard *.c)
ASM_OUTPUTS := $(patsubst %.c,%.s,$(C_SOURCES))

all: $(ASM_OUTPUTS)

%.s: %.c
	$(CC) $(CFLAGS) -S $< -o $@

.PHONY: clean

clean:
	@true
