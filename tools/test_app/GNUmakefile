# GNUmakefile - build wrapper for vendor test_app
#
# GNU make checks for GNUmakefile before Makefile, so this file takes
# precedence.  It applies compiler workarounds for known defects in the
# v2.2.1 vendor source that cause build failures under GCC 14, then
# delegates all rules and targets to the unmodified vendor Makefile.
#
# Only the three OTA translation units (libota.o, hgota.o, fwinfo.o) receive
# the extra flags; all other targets (hgicf, hgpriv, libnetat, hgics, ...) are
# compiled exactly as the vendor Makefile specifies.
#
# Toolchain setup (ARM musl libc, required for OpenIPC targets):
#   ../../scripts/setup-userspace-toolchain.sh --download
#   source ../../toolchains/env.sh
#
# To build everything:   make CC=arm-openipc-linux-musleabi-gcc
# To build only hgota:   make hgota CC=arm-openipc-linux-musleabi-gcc
# To see this help:      make help

# hgics sources (hgics.c, blenc.c, hgics_blenc.c, hgics_relay.c) are not
# included in this vendor release package.  Use 'override' before including
# Makefile so that the vendor's EXEC = ... assignment cannot add hgics back.
# (Prerequisites in 'all: $(EXEC)' are expanded immediately when parsed, so
# overriding EXEC after the include is too late.)
override EXEC := hgota libnetat hgicf hgpriv libnetat_cli

# Auto-activate toolchain from toolchains/env.sh if CC is not already on PATH.
# This makes 'make CC=arm-openipc-linux-musleabi-gcc' work without needing to
# manually 'source toolchains/env.sh' first.
DRIVER_ROOT   := $(realpath $(dir $(lastword $(MAKEFILE_LIST)))/../..)
TOOLCHAIN_ENV := $(DRIVER_ROOT)/toolchains/env.sh
ifeq ($(shell command -v $(CC) 2>/dev/null),)
  ifneq ($(wildcard $(TOOLCHAIN_ENV)),)
    export PATH := $(shell . $(TOOLCHAIN_ENV) 2>/dev/null && printf '%s' "$$PATH")
  endif
endif

# Per-toolchain output directory so native and cross builds do not overwrite
# each other.  'bin/arm-openipc-linux-musleabi-gcc' vs 'bin/cc' etc.
# The vendor Makefile unconditionally does 'rm -rf bin; mkdir bin' so we
# shadow its 'all' recipe to redirect output into the subdirectory instead.
CC_NAME     := $(notdir $(CC))
BIN_SUBDIR  := bin/$(CC_NAME)

include Makefile

# Override the vendor 'all' install step to use our subdirectory.
all: $(EXEC)
	mkdir -p $(BIN_SUBDIR)
	for i in $(EXEC); do cp -fv $$i $(BIN_SUBDIR)/$$i; done

.PHONY: help
help:
	@echo "Usage: make [target] CC=<cross-compiler>"
	@echo ""
	@echo "Targets:"
	@echo "  all             Build all: $(EXEC)"
	@echo "  hgpriv          Configuration CLI (send one iwpriv command and exit)"
	@echo "  hgicf           Firmware event daemon (long-running, tails /proc/hgicf/fwevnt)"
	@echo "  hgota           OTA firmware push utility"
	@echo "  libnetat        Vendor interactive NetAT tool"
	@echo "  libnetat_cli    Non-interactive one-shot NetAT wrapper (OpenIPC CGI/script use)"
	@echo "  help            Show this help"
	@echo ""
	@echo "Toolchain setup (ARM musl libc for OpenIPC targets):"
	@echo "  ../../scripts/setup-userspace-toolchain.sh --download"
	@echo "  source ../../toolchains/env.sh"
	@echo ""
	@echo "Build for OpenIPC ARM target:"
	@echo "  make CC=arm-openipc-linux-musleabi-gcc"
	@echo ""
	@echo "Output: bin/\$$(CC_NAME)/{hgpriv,hgicf,hgota,libnetat,libnetat_cli}"

# Extra flags scoped to OTA object files.
#   -include compat.h             : inject the shim before each TU's own includes
#   -Wno-incompatible-pointer-types: vendor passes struct pointers where char* expected
#   -Wno-implicit-function-declaration: vendor calls functions not yet declared
#   -Wno-format                   : vendor uses %x instead of %hhx for uint8* in sscanf
#     (GCC 14 promotes the first two from warnings to errors by default)
OTA_CFLAGS := -I. \
              -include compat.h \
              -Wno-incompatible-pointer-types \
              -Wno-implicit-function-declaration \
              -Wno-format

libota.o: libota.c compat.h error.h
	$(CC) $(CFLAGS) $(OTA_CFLAGS) -c -o $@ $<

hgota.o: hgota.c compat.h error.h
	$(CC) $(CFLAGS) $(OTA_CFLAGS) -c -o $@ $<

fwinfo.o: fwinfo.c compat.h error.h
	$(CC) $(CFLAGS) $(OTA_CFLAGS) -c -o $@ $<

# hgicf.c and hgpriv.c both #include iwpriv.c which has incompatible pointer
# type issues under GCC 14.
# -I. lets the local error.h stub shadow the missing system header on musl libc
# targets (musl does not ship <error.h>, a GNU glibc extension).
IWPRIV_CFLAGS := -I. \
                 -Wno-incompatible-pointer-types

hgicf: hgicf.c error.h
	$(CC) $(CFLAGS) $(LDFLAGS) $(IWPRIV_CFLAGS) -o $@ $@.c $(LDLIBS)

hgpriv: hgpriv.c error.h
	$(CC) $(CFLAGS) $(LDFLAGS) $(IWPRIV_CFLAGS) -o $@ $@.c $(LDLIBS)

libnetat: libnetat.c error.h
	$(CC) $(CFLAGS) $(LDFLAGS) -I. -o $@ $@.c $(LDLIBS)

# Non-interactive one-shot wrapper; includes libnetat.c via #include so the
# vendor source is never modified.  -D_GNU_SOURCE provides SO_BINDTODEVICE.
libnetat_cli: libnetat_cli.c libnetat.c error.h
	$(CC) $(CFLAGS) $(LDFLAGS) -I. -D_GNU_SOURCE -o $@ libnetat_cli.c $(LDLIBS)
