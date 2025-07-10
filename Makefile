CC := gcc-15
CFLAGS := -Wall -Wextra -fopenmp

TUTORIAL_DIRS := 01_tutorial 02_syntax 03_scheduling 04_task 05_attribution 06_thread 07_appendix

.PHONY: all $(TUTORIAL_DIRS)
all: $(TUTORIAL_DIRS)

$(TUTORIAL_DIRS):
	@echo "Building $@..."
	@$(MAKE) -C $@ CC="$(CC)" CFLAGS="$(CFLAGS)"

.PHONY: clean
clean:
	@for dir in $(TUTORIAL_DIRS); do \
		echo "Cleaning $$dir..."; \
		$(MAKE) -C $$dir clean; \
	done

.PHONY: clean-%
clean-%:
	@echo "Cleaning $*..."
	@$(MAKE) -C $* clean
