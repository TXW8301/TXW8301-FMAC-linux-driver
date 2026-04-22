# TXW8301 FMAC Test Applications

This directory contains the Taixin vendor test applications with build workarounds for GCC 14 compatibility. All fixes are applied **without modifying any vendor source files**, preserving the baseline for reference and future updates.

## Prerequisites

- **GCC 14 or newer** (tested with GCC 14.x)
- GNU Make
- Standard Linux build tools (libc development headers)

**Note**: These workarounds specifically address compilation issues introduced by GCC 14's stricter default error reporting. They should work with GCC 15 and later versions, though future GCC releases may introduce new warnings that would require additional suppressions.

## Quick Start

### Compilation

```bash
# From this directory
make

# Compiled binaries will be placed in bin/
ls bin/
# Output: hgota  libnetat  hgicf  hgpriv
```

### Available Tools

After building, the following utilities are available in `bin/`:

- **hgota** - OTA (Over-The-Air) firmware update tool
- **libnetat** - Network AT command interface
- **hgicf** - Wireless interface configuration utility
- **hgpriv** - Private/vendor-specific configuration tool

### Clean Build

```bash
make clean
```

## Usage Examples

### OTA Firmware Update

```bash
# Query OTA status
sudo ./bin/hgota -i <interface> -q

# Update firmware
sudo ./bin/hgota -i <interface> -f <firmware.bin>
```

### Network Configuration

```bash
# Network AT commands
./bin/libnetat <interface> <command>
```

### Wireless Configuration

```bash
# Configure wireless interface
sudo ./bin/hgicf <interface> <parameters>

# Private/vendor configuration
sudo ./bin/hgpriv <interface> <parameters>
```

## Workaround Architecture

### Problem Statement

The vendor test_app source code (v2.2.1-41305) contains several defects that prevent compilation under GCC 14:

1. **Missing headers** - Network byte-order functions used without `<arpa/inet.h>`
2. **Typo mismatch** - Header declares `fwinfo_get_fw_lenght`, source defines `fwinfo_get_fw_length`
3. **Missing includes** - Functions called without proper header inclusion
4. **Missing declarations** - Functions defined but not declared in headers
5. **Format specifier warnings** - sscanf calls use wrong format specifiers (needs hh modifier)
6. **Stricter defaults** - GCC 14 promotes incompatible-pointer-types and implicit-function-declaration warnings to errors

### Solution Design Principles

**Non-invasive approach**: Preserve vendor source files unchanged to:
- Maintain clean vendor baseline for reference
- Simplify integration of future vendor updates
- Clearly separate vendor code from local fixes

**Build-time injection**: Apply all fixes through build system:
- Custom GNUmakefile (takes precedence over Makefile)
- Compatibility header force-included via `-include` flag
- Targeted compiler warning suppressions

### Implementation Details

#### 1. GNUmakefile (Build Wrapper)

**Purpose**: Intercepts build before vendor Makefile, applies compiler workarounds

**Key mechanisms**:

```makefile
# GNU make checks GNUmakefile before Makefile
include Makefile  # Delegate to vendor Makefile

# Inject compat.h before each OTA TU's own includes
OTA_CFLAGS := -include compat.h \
              -Wno-incompatible-pointer-types \
              -Wno-implicit-function-declaration

# Apply extra flags only to affected object files
libota.o: libota.c compat.h
	$(CC) $(CFLAGS) $(OTA_CFLAGS) -c -o $@ $<
```

**Scope**: Only OTA-related translation units (libota.o, hgota.o, fwinfo.o) and iwpriv users (hgicf, hgpriv) receive extra flags. Other targets compile with vendor-original flags.

**EXEC override**: Uses `override EXEC` to remove `hgics` from the build list, since those source files are not included in this vendor release package.

#### 2. compat.h (Compatibility Shim)

**Purpose**: Fix vendor source defects without modifying source files

**Force inclusion**: `-include compat.h` flag in GNUmakefile causes compiler to process this header before each affected translation unit's own `#include` directives.

**Fixes provided**:

| Issue | Vendor Defect | Fix Applied |
|-------|---------------|-------------|
| **Missing header** | `libota.c` uses `htons/ntohl/htonl` without include | `#include <arpa/inet.h>` |
| **Typo mismatch** | Header: `fwinfo_get_fw_lenght` ↔ Source: `fwinfo_get_fw_length` | `#define fwinfo_get_fw_lenght fwinfo_get_fw_length` |
| **Missing includes** | `hgota.c` calls functions without including headers | `#include "libota.h"` and `#include "fwinfo.h"` |
| **Missing declarations** | `libota_query_config`, `libota_sta_config`, `libota_update_config` defined but not in `libota.h` | Forward declarations added |
| **Format specifiers** | `hgota.c` sscanf calls use wrong format specifiers | `-Wno-format` in GNUmakefile |
| **GCC 14 strict errors** | Incompatible pointer types, implicit declarations | Warning suppressions in GNUmakefile |

**Header guard safety**: compat.h includes libota.h and fwinfo.h, which are safe to include multiple times due to their include guards.

#### 3. Targeted Warning Suppressions

**OTA translation units**:
```makefile
-Wno-incompatible-pointer-types     # Vendor passes struct * where char* expected
-Wno-implicit-function-declaration  # Vendor calls undeclared functions
-Wno-format                         # Vendor uses wrong format specifiers in sscanf
```

**iwpriv users** (hgicf.c, hgpriv.c):
```makefile
-Wno-incompatible-pointer-types  # iwpriv.c has pointer type issues
```

These flags are **only** applied to the specific translation units with issues. All other code compiles with default (strict) warnings.

### File Ownership

| File | Status | Notes |
|------|--------|-------|
| `Makefile` | **Vendor baseline** | Unmodified, preserved from v2.2.1-41305 |
| `*.c`, `*.h` (vendor) | **Vendor baseline** | All source unchanged |
| `GNUmakefile` | **Local workaround** | Build wrapper, not in vendor package |
| `compat.h` | **Local workaround** | Compatibility shim, not in vendor package |
| `bin/` | **Build artifacts** | Generated at compile time |

### Maintenance Notes

**Vendor updates**: When Taixin releases new driver versions:

1. Replace vendor Makefile and source files
2. Verify GNUmakefile and compat.h still apply cleanly
3. Test build and adjust workarounds if needed

**Upstreaming**: If Taixin fixes these issues in future releases, the workarounds can be retired:

- Remove GNUmakefile (fall back to vendor Makefile)
- Remove compat.h
- Remove this documentation

**GCC compatibility**: If building on GCC < 14 or compilers with more permissive defaults, the workarounds are harmless but may not be strictly necessary.

## Technical Background

### GCC 14 Breaking Changes

GCC 14 changed default warning behavior, promoting several warnings to errors:
- `-Werror=incompatible-pointer-types` (previously just a warning)
- `-Werror=implicit-function-declaration` (previously just a warning)

This affects legacy code that:
- Passes pointers without proper type casting
- Calls functions before declaration/prototype
- Uses standard library functions without including proper headers

### Build System Precedence

GNU make checks for filenames in this order:
1. **GNUmakefile** ← Our wrapper lives here
2. Makefile
3. makefile

By placing our wrapper in GNUmakefile, we intercept the build before the vendor Makefile is seen, then explicitly include it.

## Related Documentation

- Vendor changelog: `../../changelog.txt`
- Driver development guide: `../../../../Docs/EN/TaiXin_Semiconductor_Linux_WiFi_FMAC_Driver_Development Guide_*/`
- Main driver README: `../../README.md`

## Version Information

- **Vendor package**: taixin-fmac-linux-driver-v2.2.1-41305
- **Workaround version**: 1.0
- **Last updated**: 2026-04-23
- **Tested with**: GCC 14.x on Linux
