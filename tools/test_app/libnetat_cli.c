/*
 * libnetat_cli.c — non-interactive one-shot wrapper for OpenIPC debug use.
 *
 * Vendor libnetat.c is included verbatim.  A local #define renames the vendor
 * interactive main() before the include; #undef restores the symbol for this
 * file's replacement main().  libnetat.c is never modified.
 *
 * All static helpers (netat_scan, sock_send, sock_recv, random_bytes) and the
 * global `libnetat` struct are in the same translation unit after the include,
 * so no vendor source changes are needed.
 *
 * CLI contract:
 *   libnetat_cli <if>                          interactive mode (vendor behaviour)
 *   libnetat_cli <if> scan                     discover devices, one MAC per line
 *   libnetat_cli <if> "<AT command>"           send command (auto-discover target)
 *   libnetat_cli <if> "<AT command>" <mac>     send command to specific device
 *
 * Exit codes: 0 = success,  1 = error (no device / timeout / bad args / bad MAC)
 * Errors always go to stderr; device responses always go to stdout.
 *
 * Build: see GNUmakefile target 'libnetat_cli'
 *   make CC=arm-openipc-linux-musleabi-gcc libnetat_cli
 */

#define main __vendor_main__   /* rename vendor main; #undef'd below */
#include "libnetat.c"
#undef main

/* ------------------------------------------------------------------ helpers */

/*
 * Socket-only init: same setup as libnetat_init() but without the discovery
 * scan that prints "auto select device ..." to stdout.
 */
static int cli_init_socket(const char *ifname)
{
    int on = 1;
    struct sockaddr_in local_addr;
    struct ifreq req;

    memset(libnetat.dest, 0xff, 6);   /* broadcast until a device is known */
    libnetat.sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (libnetat.sock < 0) {
        fprintf(stderr, "error: socket: %s\n", strerror(errno));
        return -1;
    }

    if (setsockopt(libnetat.sock, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on)) < 0) {
        fprintf(stderr, "error: SO_BROADCAST: %s\n", strerror(errno));
        close(libnetat.sock);
        return -1;
    }

    memset(&req, 0, sizeof(req));
    strncpy(req.ifr_name, ifname, IFNAMSIZ - 1);
    if (setsockopt(libnetat.sock, SOL_SOCKET, SO_BINDTODEVICE, &req, sizeof(req)) < 0) {
        fprintf(stderr, "error: SO_BINDTODEVICE '%s': %s\n", ifname, strerror(errno));
        close(libnetat.sock);
        return -1;
    }

    memset(&local_addr, 0, sizeof(local_addr));
    local_addr.sin_family      = AF_INET;
    local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    local_addr.sin_port        = htons(NETAT_PORT);
    if (bind(libnetat.sock, (struct sockaddr *)&local_addr, sizeof(local_addr)) < 0) {
        fprintf(stderr, "error: bind: %s\n", strerror(errno));
        close(libnetat.sock);
        return -1;
    }

    random_bytes(libnetat.cookie, 6);
    return 0;
}

/* Parse "xx:xx:xx:xx:xx:xx" into 6-byte array.  Returns 0 on success. */
static int cli_parse_mac(const char *mac_str, char *mac)
{
    int v[6];
    if (sscanf(mac_str, MACSTR, &v[0], &v[1], &v[2], &v[3], &v[4], &v[5]) != 6) {
        fprintf(stderr, "error: invalid MAC address '%s' (expected xx:xx:xx:xx:xx:xx)\n",
                mac_str);
        return -1;
    }
    for (int i = 0; i < 6; i++)
        mac[i] = (char)v[i];
    return 0;
}

/*
 * Scan for all responding devices; print one MAC per line.
 * Returns device count (0 = none found).
 */
static int cli_scan(void)
{
    char devices[128][6];
    int num = 0, ret;
    struct sockaddr_in from;
    struct wnb_netat_cmd *cmd;

    netat_scan();
    do {
        memset(libnetat.recvbuf, 0, NETAT_BUFF_SIZE);
        ret = sock_recv(libnetat.sock, &from, libnetat.recvbuf, NETAT_BUFF_SIZE, 1000);
        if (ret >= (int)sizeof(struct wnb_netat_cmd)) {
            cmd = (struct wnb_netat_cmd *)libnetat.recvbuf;
            if (cmd->cmd == WNB_NETAT_CMD_SCAN_RESP && num < 128)
                memcpy(devices[num++], cmd->src, 6);
        }
    } while (ret > 0);

    if (num == 0) {
        fprintf(stderr, "error: no devices found\n");
        return 0;
    }
    for (int i = 0; i < num; i++)
        printf(MACSTR "\n", MAC2STR(devices[i]));
    return num;
}

/*
 * Auto-discover first responding device; sets libnetat.dest.
 * Returns 1 if found, 0 if none.
 */
static int cli_discover(void)
{
    int ret;
    struct sockaddr_in from;
    struct wnb_netat_cmd *cmd;

    netat_scan();
    do {
        memset(libnetat.recvbuf, 0, NETAT_BUFF_SIZE);
        ret = sock_recv(libnetat.sock, &from, libnetat.recvbuf, NETAT_BUFF_SIZE, 1000);
        if (ret >= (int)sizeof(struct wnb_netat_cmd)) {
            cmd = (struct wnb_netat_cmd *)libnetat.recvbuf;
            if (cmd->cmd == WNB_NETAT_CMD_SCAN_RESP) {
                memcpy(libnetat.dest, cmd->src, 6);
                return 1;
            }
        }
    } while (ret > 0);
    return 0;
}

/*
 * Receive AT responses into buff.  Waits up to 10 s, collects all fragments.
 * Returns bytes written (0 = nothing received).
 * Note: vendor netat_recv() has no explicit return and prints \r\n noise;
 * this replaces it for one-shot use.
 */
static int cli_recv_at(char *buff, int bufsize)
{
    int ret, off = 0, datalen;
    struct sockaddr_in from;
    struct wnb_netat_cmd *cmd;

    do {
        memset(libnetat.recvbuf, 0, NETAT_BUFF_SIZE);
        ret = sock_recv(libnetat.sock, &from, libnetat.recvbuf, NETAT_BUFF_SIZE, 10000);
        if (ret >= (int)sizeof(struct wnb_netat_cmd)) {
            cmd = (struct wnb_netat_cmd *)libnetat.recvbuf;
            if (memcmp(cmd->dest, libnetat.cookie, 6) == 0 &&
                cmd->cmd == WNB_NETAT_CMD_AT_RESP) {
                datalen = ret - (int)sizeof(struct wnb_netat_cmd);
                if (datalen > 0 && off + datalen < bufsize - 1) {
                    memcpy(buff + off, cmd->data, datalen);
                    off += datalen;
                }
            }
        }
    } while (ret > 0);

    buff[off] = '\0';
    return off;
}

/* -------------------------------------------------------------------- main */

int main(int argc, char *argv[])
{
    char response[NETAT_BUFF_SIZE];
    int ret;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <interface> [command] [dest_mac]\n", argv[0]);
        fprintf(stderr, "  %s <if> scan                    discover devices, one MAC per line\n", argv[0]);
        fprintf(stderr, "  %s <if> \"<AT command>\"          send command (auto-discover target)\n", argv[0]);
        fprintf(stderr, "  %s <if> \"<AT command>\" <mac>    send command to specific device\n", argv[0]);
        fprintf(stderr, "  %s <if>                         interactive mode\n", argv[0]);
        fprintf(stderr, "Exit codes: 0=success  1=error (no device / timeout / bad args)\n");
        return 1;
    }

    /* Interactive mode: forward directly to vendor main (takes only <ifname>) */
    if (argc == 2) {
        char *iargs[] = { argv[0], argv[1] };
        return __vendor_main__(2, iargs);
    }

    /* One-shot mode: init socket without discovery side-effects */
    if (argc >= 4) {
        /* Pre-set dest MAC so discovery is skipped */
        if (cli_parse_mac(argv[3], libnetat.dest) < 0)
            return 1;
    }

    if (cli_init_socket(argv[1]) < 0)
        return 1;

    if (strcmp(argv[2], "scan") == 0) {
        ret = cli_scan();
        close(libnetat.sock);
        return (ret > 0) ? 0 : 1;
    }

    /* AT command mode */
    if (libnetat.dest[0] & 0x1) {
        /* dest still broadcast — auto-discover */
        if (!cli_discover()) {
            fprintf(stderr, "error: no device detected\n");
            close(libnetat.sock);
            return 1;
        }
    }

    netat_send(argv[2]);
    ret = cli_recv_at(response, sizeof(response));
    close(libnetat.sock);

    if (ret <= 0) {
        fprintf(stderr, "error: no response (send timeout or device not reachable)\n");
        return 1;
    }

    printf("%s", response);
    return 0;
}
