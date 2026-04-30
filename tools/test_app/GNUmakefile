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
# To build everything:   make
# To build only hgota:   make hgota

# hgics sources (hgics.c, blenc.c, hgics_blenc.c, hgics_relay.c) are not
# included in this vendor release package.  Use 'override' before including
# Makefile so that the vendor's EXEC = ... assignment cannot add hgics back.
# (Prerequisites in 'all: $(EXEC)' are expanded immediately when parsed, so
# overriding EXEC after the include is too late.)
override EXEC := hgota libnetat hgicf hgpriv

include Makefile

# Extra flags scoped to OTA object files.
#   -include compat.h             : inject the shim before each TU's own includes
#   -Wno-incompatible-pointer-types: vendor passes struct pointers where char* expected
#   -Wno-implicit-function-declaration: vendor calls functions not yet declared
#   -Wno-format                   : vendor uses %x instead of %hhx for uint8* in sscanf
#     (GCC 14 promotes the first two from warnings to errors by default)
OTA_CFLAGS := -include compat.h \
              -Wno-incompatible-pointer-types \
              -Wno-implicit-function-declaration \
              -Wno-format

libota.o: libota.c compat.h
	$(CC) $(CFLAGS) $(OTA_CFLAGS) -c -o $@ $<

hgota.o: hgota.c compat.h
	$(CC) $(CFLAGS) $(OTA_CFLAGS) -c -o $@ $<

fwinfo.o: fwinfo.c compat.h
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
