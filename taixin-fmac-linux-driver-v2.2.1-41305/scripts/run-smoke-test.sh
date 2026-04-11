#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$DRIVER_DIR/logs/smoke-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$LOG_DIR"

usage() {
    cat <<USAGE
Usage: $0 [--target user@host] [--ko PATH] [--fw PATH]

If --target is provided, the script will SCP the module to the remote
target and run the tests there (requires SSH access).
If omitted, the script runs locally (execute on the target).

Examples:
  # Remote test
  $0 --target root@192.168.1.50 --ko ko/hgicf.ko --fw firmware/hgicf.bin

  # Local test (run on target)
  sudo $0 --ko ko/hgicf.ko --fw /lib/firmware/hgicf.bin
USAGE
    exit 1
}

TARGET=""
KO="$DRIVER_DIR/ko/hgicf.ko"
FW=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --ko) KO="$2"; shift 2 ;;
        --fw) FW="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown arg: $1"; usage ;;
    esac
done

echo "Smoke test logs: $LOG_DIR"
echo "Module: $KO"
[[ -n "$FW" ]] && echo "Firmware: $FW"

if [[ -n "$TARGET" ]]; then
    SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    SSH="ssh $SSH_OPTS $TARGET"
    SCP="scp $SSH_OPTS"
    TMPDIR="/tmp/hgicf-smoke"

    echo "Preparing remote target $TARGET..."
    $SSH "mkdir -p $TMPDIR" || true
    echo "Copying module to remote target..."
    $SCP "$KO" "$TARGET:$TMPDIR/"

    if [[ -n "$FW" && -f "$FW" ]]; then
        echo "Copying firmware to remote target (to be moved to /lib/firmware)..."
        $SCP "$FW" "$TARGET:$TMPDIR/"
        $SSH "sudo mv $TMPDIR/$(basename "$FW") /lib/firmware/ || true; sudo sync || true"
    fi

    echo "Clearing remote dmesg (requires sudo)..."
    $SSH "sudo dmesg -C || true"

    echo "Loading module on remote target"
    $SSH "sudo insmod $TMPDIR/$(basename "$KO") || (sudo rmmod hgicf 2>/dev/null || true; sudo insmod $TMPDIR/$(basename \"$KO\"))"
    sleep 2

    echo "Collecting logs from remote target..."
    $SSH "dmesg | tail -n 200" > "$LOG_DIR/dmesg.txt" || true
    $SSH "ip link" > "$LOG_DIR/iplink.txt" || true
    $SSH "iw dev || true" > "$LOG_DIR/iwdev.txt" 2>/dev/null || true

    echo "Remote smoke test finished. Logs: $LOG_DIR"
else
    echo "Running smoke test locally..."
    sudo dmesg -C || true
    sudo insmod "$KO" || (sudo rmmod hgicf 2>/dev/null || true; sudo insmod "$KO")
    sleep 2
    dmesg | tail -n 200 > "$LOG_DIR/dmesg.txt" || true
    ip link > "$LOG_DIR/iplink.txt" || true
    iw dev > "$LOG_DIR/iwdev.txt" 2>/dev/null || true
    echo "Local smoke test finished. Logs: $LOG_DIR"
fi

exit 0
