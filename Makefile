CC = gcc
CFLAGS = -g -O2 -fPIC -DEVERYUTIL_BUILD -Wall -O2 $(shell find include -type d -name "*" -exec echo -I{} \;)
LDFLAGS = 
AR = ar
RANLIB = ranlib
SRC_DIR = src
INCLUDE_DIR = include
BUILD_DIR = build
TEST_DIR = tests
LIB_NAME = everyutil
LIB_STATIC = $(BUILD_DIR)/lib$(LIB_NAME).a
LIB_SHARED = $(BUILD_DIR)/lib$(LIB_NAME).so
PREFIX = /mingw64
exec_prefix = ${prefix}
libdir = ${exec_prefix}/lib
includedir = ${prefix}/include

ifeq ($(OS),Windows_NT)
    LIB_SHARED := $(BUILD_DIR)/lib$(LIB_NAME).dll
    LIB_IMPORT := $(BUILD_DIR)/lib$(LIB_NAME).lib
    TEST_BIN := $(BUILD_DIR)/test_utils.exe
else
    TEST_BIN := $(BUILD_DIR)/test_utils
endif

# Collect all source files from any subdirectory under src/
SRC_FILES = $(shell find $(SRC_DIR) -name '*.c')
OBJ_FILES = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRC_FILES))
# Collect all test source files from any subdirectory under tests/
TEST_SRC = $(shell find $(TEST_DIR) -name '*.c')
TEST_OBJ = $(patsubst $(TEST_DIR)/%.c,$(BUILD_DIR)/%.test.o,$(TEST_SRC))
TEST_EXEC_DIR = $(BUILD_DIR)/testExecutables
TEST_EXECUTABLES = $(patsubst $(TEST_DIR)/%.c,$(TEST_EXEC_DIR)/%.exe,$(TEST_SRC))

.PHONY: all clean test static shared install uninstall

all: | $(BUILD_DIR) static shared test

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR) $(shell find $(SRC_DIR) -type d -exec echo $(BUILD_DIR)/{} \; | sed 's|$(SRC_DIR)/||g') $(shell find $(TEST_DIR) -type d -exec echo $(TEST_EXEC_DIR)/{} \; | sed 's|$(TEST_DIR)/||g')

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(LIB_STATIC): $(OBJ_FILES)
	$(AR) rcs $@ $^
	$(RANLIB) $@

$(LIB_SHARED): $(OBJ_FILES)
	$(CC) -shared -o $@ $^ $(LDFLAGS)
ifeq ($(OS),Windows_NT)
	$(CC) -shared -o $@ $^ $(LDFLAGS) -Wl,--out-implib,$(LIB_IMPORT)
endif

$(BUILD_DIR)/%.test.o: $(TEST_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(TEST_EXEC_DIR)/%.exe: $(BUILD_DIR)/%.test.o $(LIB_STATIC)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $< $(LIB_STATIC) -o $@ $(LDFLAGS)

$(TEST_BIN): $(TEST_OBJ) $(LIB_STATIC)
	$(CC) $(CFLAGS) $(TEST_OBJ) $(LIB_STATIC) -o $@ $(LDFLAGS)

static: $(LIB_STATIC)

shared: $(LIB_SHARED)

test: $(TEST_EXECUTABLES)
	@for exe in $(TEST_EXECUTABLES); do \
		echo "Running $$exe"; \
		./$$exe; \
	done

install: $(LIB_STATIC) $(LIB_SHARED)
	@mkdir -p $(PREFIX)/lib $(PREFIX)/include $(PREFIX)/lib/pkgconfig
	cp $(LIB_STATIC) $(LIB_SHARED) $(PREFIX)/lib
ifeq ($(OS),Windows_NT)
	cp $(LIB_IMPORT) $(PREFIX)/lib
endif
	@find $(INCLUDE_DIR) -type d -name "*" -exec mkdir -p $(PREFIX)/include/{} \;
	@find $(INCLUDE_DIR) -type f -name "*.h" -exec cp {} $(PREFIX)/include/{} \;
	sed 's|@PREFIX@|$(PREFIX)|g' pkgconfig/everyutil.pc > $(PREFIX)/lib/pkgconfig/everyutil.pc

uninstall:
	rm -f $(PREFIX)/lib/lib$(LIB_NAME).a $(PREFIX)/lib/lib$(LIB_NAME).so $(PREFIX)/lib/lib$(LIB_NAME).dll $(PREFIX)/lib/lib$(LIB_NAME).lib
	rm -rf $(PREFIX)/include/*
	rm -f $(PREFIX)/lib/pkgconfig/everyutil.pc

clean:
	rm -rf $(BUILD_DIR)
