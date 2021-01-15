PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/obj
BUILD280 = $(MIX_APP_PATH)/obj280

# Check that we're on a supported build platform
ifeq ($(CROSSCOMPILE),)
    # Not crosscompiling, so check that we're on Linux.
    ifneq ($(shell uname -s),Linux)
        $(warning Elixir Bme680 only works on Linux, but cross compilation)
        $(warning is supported by defining $$CROSSCOMPILE, $$ERL_EI_INCLUDE_DIR,)
        $(warning and $$ERL_EI_LIBDIR. See Makefile for details. If using Nerves,)
        $(warning this should be done automatically.)
        $(warning .)
        $(warning Skipping C compilation unless targets explicitly passed to make.)
				DEFAULT_TARGETS = $(PREFIX)
    endif
endif

CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter

HEADER_FILES = src src_bme280

SRC = $(wildcard src/*.c)
SRC280 = $(wildcard src_bme280/*.c)

OBJ = $(SRC:src/%.c=$(BUILD)/%.o)

OBJ280 = $(SRC280:src_bme280/%.c=$(BUILD280)/%.o)

DEFAULT_TARGETS ?= $(PREFIX) $(BUILD) $(BUILD280) $(PREFIX)/bme680 $(PREFIX)/bme280

calling_from_make:
	mix compile

all: $(DEFAULT_TARGETS)

$(PREFIX)/bme680: $(OBJ)
	$(CC) $^ $(LDFLAGS) $(LDLIBS) -o $@

$(PREFIX)/bme280: $(OBJ280)
	$(CC) $^ $(LDFLAGS) $(LDLIBS) -o $@

$(BUILD)/%.o: src/%.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(BUILD280)/%.o: src_bme280/%.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(PREFIX) $(BUILD) $(BUILD280):
	mkdir -p $@

clean:
	rm -rf $(PREFIX)
	rm -f $(OBJ)
	rm -f $(OBJ280)

.PHONY: calling_from_make all clean
