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

CFLAGS = -g

HEADER_FILES = src

SRC = $(wildcard src/*.c)

OBJ = $(SRC:.c=.o)

DEFAULT_TARGETS ?= priv priv/bme680

all: $(DEFAULT_TARGETS)

priv/bme680: src/main.o $(OBJ)
	$(CC) $^ -I $(HEADER_FILES) -o $@ $(LDFLAGS) $(OBJ) $(LDLIBS)

priv:
	mkdir -p priv

clean:
	rm -f priv $(OBJ)
