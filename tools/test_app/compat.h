/*
 * compat.h - Compiler compatibility shim for vendor test_app
 *
 * Force-included via -include compat.h (GNUmakefile, OTA targets only).
 * Fixes known defects in the v2.2.1 vendor source that cause build failures
 * under GCC 14, without modifying any vendor source file.
 *
 * Issues addressed:
 *   1. libota.c uses htons/ntohl/htonl without including <arpa/inet.h>.
 *   2. fwinfo.h declares 'fwinfo_get_fw_lenght' (typo); fwinfo.c defines
 *      and hgota.c calls 'fwinfo_get_fw_length' (correct spelling).
 *      A macro alias resolves the mismatch.
 *   3. hgota.c calls fwinfo_get_fw_length without including fwinfo.h.
 *   4. hgota.c calls libota_query_config / libota_sta_config /
 *      libota_update_config which are defined in libota.c but not declared
 *      in the vendor libota.h.
 *   5. GCC 14 promotes -Wincompatible-pointer-types and
 *      -Wimplicit-function-declaration to errors; suppressed via GNUmakefile
 *      OTA_CFLAGS for the affected translation units.
 */

#ifndef TAIXIN_COMPAT_H
#define TAIXIN_COMPAT_H

/* Fix 1: provide htons / ntohl / htonl / ntohs for libota.c */
#include <arpa/inet.h>

/* Fix 2: redirect the typo declaration in fwinfo.h to the correct symbol */
#define fwinfo_get_fw_lenght fwinfo_get_fw_length

/*
 * Fix 3 + 4: pull in libota.h (typedefs needed below) and fwinfo.h
 * (missing include in hgota.c).  Include guards make these no-ops when the
 * translation unit already includes them.
 */
#include "libota.h"
#include "fwinfo.h"

/* Fix 4: forward-declare functions defined in libota.c but absent from
 * the vendor libota.h header. */
int libota_query_config(char *sta_mac);
int libota_sta_config(char *sta_mac, struct eth_ota_fwparam *param);
int libota_update_config(char *sta_mac, struct eth_ota_fwparam *param);

#endif /* TAIXIN_COMPAT_H */
