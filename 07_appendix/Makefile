CC := gcc-15
CFLAGS := -Wall -Wextra -fopenmp

EXCLUDE_FILES := atomic1.c atomic2.c matmul_gpu.c

C_SOURCES := $(filter-out $(EXCLUDE_FILES),$(wildcard *.c))
C_EXECUTABLES := $(patsubst %.c,%,$(C_SOURCES))

all: $(C_EXECUTABLES)

%: %.c
	$(CC) $(CFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -f $(C_EXECUTABLES) 
