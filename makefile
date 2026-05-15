CC = gcc
SRC_DIR = ./source/system_programs
BIN_DIR = ./bin
LIB_DIR = ./source/libs
LIB_SOURCES = $(wildcard $(LIB_DIR)/*.c)
SOURCES = $(wildcard $(SRC_DIR)/*.c)
OBJECTS = $(SOURCES:$(SRC_DIR)/%.c=$(BIN_DIR)/%)
MAIN_SRC = ./source/shell.c # add more source files here
MAIN_EXEC = cseshell

# ----------------------------------------------------------------------
# Test infrastructure
# ----------------------------------------------------------------------
TESTS_DIR = ./tests
UNIT_DIR = $(TESTS_DIR)/unit
INTEGRATION_DIR = $(TESTS_DIR)/integration
UNITY_DIR = $(TESTS_DIR)/unity
UNIT_BIN_DIR = $(UNIT_DIR)/bin

# Auto-discover every tests/unit/test_*.c file.
UNIT_SOURCES = $(wildcard $(UNIT_DIR)/test_*.c)
UNIT_BINS = $(UNIT_SOURCES:$(UNIT_DIR)/%.c=$(UNIT_BIN_DIR)/%)

# -I./source/libs so tests can #include "rc_parser.h" etc.
# -I$(UNITY_DIR) so tests can #include "unity.h".
TEST_CFLAGS = -I./source/libs -I$(UNITY_DIR) -Wall -Wextra

# ----------------------------------------------------------------------
# Build targets (existing)
# ----------------------------------------------------------------------

# Special rule for main executable
all: $(OBJECTS) $(MAIN_EXEC)

$(BIN_DIR)/%: $(SRC_DIR)/%.c $(LIB_SOURCES)
	@mkdir -p $(BIN_DIR)
	$(CC) $^ -o $@

# $< refers to the first dependency, here it is ./source/shell.c
# if you have more dependencies, use $^ instead
# $@: This variable represents the target of the rule
# It is the filename of the file that is being generated or updated by the rule, e.g: MAIN_EXEC (cseshell)
$(MAIN_EXEC): $(MAIN_SRC) $(LIB_SOURCES)
	$(CC) $^ -o $@

# ----------------------------------------------------------------------
# Test targets (added for PA1 testing)
# ----------------------------------------------------------------------

# Naming convention: tests/unit/test_FOO.c is compiled together with
# source/libs/FOO.c and tests/unity/unity.c into tests/unit/bin/test_FOO.
#
# If your helper needs additional source files, set EXTRA_SRC on the
# per-target line, for example:
#
#   $(UNIT_BIN_DIR)/test_complex: EXTRA_SRC = ./source/libs/extra.c
#
# Unit tests are compiled with all reusable library code under source/libs/.
# This lets tests include headers from source/libs/ and link against the
# corresponding implementations.
$(UNIT_BIN_DIR)/test_%: $(UNIT_DIR)/test_%.c $(UNITY_DIR)/unity.c $(LIB_SOURCES)
	@mkdir -p $(UNIT_BIN_DIR)
	$(CC) $(TEST_CFLAGS) $^ $(EXTRA_SRC) -o $@

# Fallback rule for self-contained tests with no paired source/ file
# (e.g., test_perms.c, which copies the function inline). Make falls
# through to this rule when ./source/<name>.c does not exist.
$(UNIT_BIN_DIR)/test_%: $(UNIT_DIR)/test_%.c $(UNITY_DIR)/unity.c
	@mkdir -p $(UNIT_BIN_DIR)
	$(CC) $(TEST_CFLAGS) $^ $(EXTRA_SRC) -o $@

# Run every compiled unit test in tests/unit/bin/.
# Note: do not run with -j (parallel) if your tests touch shared files.
unit: $(UNIT_BINS)
	@echo "==> Running unit tests"
	@pass=0; fail=0; \
	for t in $(UNIT_BINS); do \
	  echo "--- $$t ---"; \
	  if $$t; then pass=$$((pass+1)); else fail=$$((fail+1)); fi; \
	done; \
	echo ""; \
	echo "Unit tests: $$pass passed, $$fail failed"; \
	test $$fail -eq 0

# Run every shell script under tests/integration/.
# Requires that cseshell and bin/* have been built.
# Note: integration tests are run serially because they may write .cseshellrc
# or other shared files in the project root.
integration: $(MAIN_EXEC) $(OBJECTS)
	@echo "==> Running integration tests"
	@pass=0; fail=0; \
	for s in $(INTEGRATION_DIR)/*.sh; do \
	  [ -f "$$s" ] || continue; \
	  echo "--- $$s ---"; \
	  if bash $$s; then pass=$$((pass+1)); else fail=$$((fail+1)); fi; \
	done; \
	echo ""; \
	echo "Integration tests: $$pass passed, $$fail failed"; \
	test $$fail -eq 0

# Run both unit and integration tests.
test: unit integration

# Invoke the AI-assisted unit test generator for one module.
# Usage:
#   make ai-unit-tests MODULE=rc_parser
ai-unit-tests:
	@if [ -z "$(MODULE)" ]; then \
	  echo "Usage: make ai-unit-tests MODULE=name"; \
	  echo "  Looks for source/name.h and source/name.c"; \
	  echo "  Generates tests/unit/test_name.c"; \
	  exit 1; \
	fi
	@bash ./scripts/gen_unit_tests.sh $(MODULE)

# ----------------------------------------------------------------------
# Clean (extended to also remove test binaries)
# ----------------------------------------------------------------------
clean:
	rm -f $(OBJECTS) $(MAIN_EXEC)
	rm -rf $(UNIT_BIN_DIR)

.PHONY: all clean unit integration test ai-unit-tests
