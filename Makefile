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
				DEFAULT_TARGETS = priv
    endif
endif

CC ?= $(CROSSCOMPILE)-gcc

CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter

HEADER_FILES = src src_bme280

SRC = $(wildcard src/*.c)
SRC280 = $(wildcard src_bme280/*.c )

OBJ = $(SRC:.c=.o)

OBJ280 = $(SRC280:.c=.o)

DEFAULT_TARGETS ?= priv priv/bme680 priv/bme280

all: $(DEFAULT_TARGETS)

priv/bme680: $(OBJ)
	$(CC) $^ $(LDFLAGS) $(LDLIBS) -o $@

priv/bme280: $(OBJ280)
	$(CC) $^ $(LDFLAGS) $(LDLIBS) -o $@

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

priv:
	mkdir -p priv

clean:
	rm -rf priv
	rm -f $(OBJ)
	rm -f $(OBJ280)
