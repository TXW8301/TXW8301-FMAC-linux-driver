/* error.h - local stub for musl libc compatibility
 *
 * musl does not provide <error.h> (a GNU glibc extension).
 * The vendor source includes it in hgicf.c, hgpriv.c, and iwpriv.c but
 * never calls error() -- only perror() is used, which is in <stdio.h>.
 *
 * This stub is picked up instead of the system header when -I. is in CFLAGS.
 * On glibc hosts the real error.h is found first via the system include path
 * (glibc paths come before -I. in the compiler's angle-bracket search order
 * only when using -isystem; with -I. the local file wins, so the guard
 * below makes it a no-op on glibc to avoid conflicts).
 */
#ifndef _ERROR_H
#define _ERROR_H

#ifndef __GLIBC__
#include <stdio.h>   /* for stderr */
#include <stdarg.h>
#include <stdlib.h>  /* for exit() */

static inline void __attribute__((unused))
error(int status, int errnum, const char *fmt, ...)
{
    /* vendor code never calls this; stub is sufficient */
    (void)status; (void)errnum; (void)fmt;
}
#endif /* !__GLIBC__ */

#endif /* _ERROR_H */
