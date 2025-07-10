CC := gcc-15
CFLAGS := -Wall -Wextra -fopenmp

C_EXECUTABLES := $(patsubst %.c,%,$(wildcard *.c))

all: $(C_EXECUTABLES)

%: %.c
	$(CC) $(CFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -f $(C_EXECUTABLES) 
