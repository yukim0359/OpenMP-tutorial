CC := gcc
CFLAGS := -Wall -Wextra -fopenmp

BUILD_DIRS := \
	01_openmp \
	02_loop \
	03_correct_parallel/shared_private \
	03_correct_parallel/data_race \
	04_fast_parallel/scheduling \
	04_fast_parallel/threads \
	05_other_syntax \
	05_other_syntax/task \
	06_appendix/simd \
	06_appendix/examples \
	06_appendix/implementation

.PHONY: all clean $(BUILD_DIRS)

all: $(BUILD_DIRS)

$(BUILD_DIRS):
	@echo "Building $@..."
	@$(MAKE) -C $@ CC="$(CC)" CFLAGS="$(CFLAGS)"

clean:
	@for dir in $(BUILD_DIRS); do \
		echo "Cleaning $$dir..."; \
		$(MAKE) -C $$dir clean; \
	done

.PHONY: clean-%
clean-%:
	@echo "Cleaning $*..."
	@$(MAKE) -C $* clean
