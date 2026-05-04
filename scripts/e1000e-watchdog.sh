#!/usr/bin/env bash

# e1000e NIC Watchdog
# Monitors for Intel e1000e TX descriptor ring hangs and attempts automatic recovery.
# The Dell Proxmox node's Intel I217 NIC occasionally hangs under sustained load,
# logging "Detected Hardware Unit Hang" messages. The driver never auto-recovers,
# requiring a module reload or reboot. This script automates recovery.
#
# Install:
#   scp e1000e-watchdog.sh root@10.0.0.4:/usr/local/bin/
#   scp e1000e-watchdog.service e1000e-watchdog.timer root@10.0.0.4:/etc/systemd/system/
#   ssh root@10.0.0.4 "chmod +x /usr/local/bin/e1000e-watchdog.sh && systemctl daemon-reload && systemctl enable --now e1000e-watchdog.timer"

set -euo pipefail

# Configuration
INTERFACE="${E1000E_INTERFACE:-eno1}"
BRIDGE="${E1000E_BRIDGE:-vmbr0}"
STATE_FILE="/tmp/e1000e-watchdog.state"
MAX_RECOVERIES_PER_HOUR=3
HANG_PATTERN="e1000e.*Detected Hardware Unit Hang"
SOFT_RESET_WAIT=10

log_info() {
    logger -t "e1000e-watchdog" -p daemon.info "$1"
}

log_warn() {
    logger -t "e1000e-watchdog" -p daemon.warning "$1"
}

log_err() {
    logger -t "e1000e-watchdog" -p daemon.err "$1"
}

# Check if we've exceeded the recovery limit for this hour
check_rate_limit() {
    if [[ ! -f "$STATE_FILE" ]]; then
        return 0
    fi

    local now
    now=$(date +%s)
    local one_hour_ago=$((now - 3600))
    local count=0

    while IFS= read -r timestamp; do
        if [[ "$timestamp" -ge "$one_hour_ago" ]]; then
            count=$((count + 1))
        fi
    done < "$STATE_FILE"

    if [[ "$count" -ge "$MAX_RECOVERIES_PER_HOUR" ]]; then
        log_err "Rate limit reached: $count recoveries in the last hour (max $MAX_RECOVERIES_PER_HOUR). Skipping."
        return 1
    fi

    return 0
}

# Record a recovery attempt timestamp and prune old entries
record_recovery() {
    local now
    now=$(date +%s)
    local one_hour_ago=$((now - 3600))

    # Prune entries older than 1 hour, then append current timestamp
    if [[ -f "$STATE_FILE" ]]; then
        local tmp
        tmp=$(mktemp)
        while IFS= read -r timestamp; do
            if [[ "$timestamp" -ge "$one_hour_ago" ]]; then
                echo "$timestamp"
            fi
        done < "$STATE_FILE" > "$tmp"
        mv "$tmp" "$STATE_FILE"
    fi

    echo "$now" >> "$STATE_FILE"
}

# Check for recent hang messages in kernel log
detect_hang() {
    if dmesg --time-format iso 2>/dev/null | tail -n 200 | grep -qP "$HANG_PATTERN"; then
        # Verify the message is recent (last 60 seconds) using journalctl
        if journalctl -k --since "60 seconds ago" --no-pager 2>/dev/null | grep -qP "$HANG_PATTERN"; then
            return 0
        fi
    fi
    return 1
}

# Attempt soft reset: bring interface down and back up
soft_reset() {
    log_warn "Attempting soft reset on $INTERFACE"
    ip link set "$INTERFACE" down
    sleep 1
    ip link set "$INTERFACE" up
    sleep "$SOFT_RESET_WAIT"
}

# Attempt hard reset: reload the e1000e kernel module
hard_reset() {
    log_warn "Soft reset failed, attempting e1000e module reload"
    ip link set "$INTERFACE" down 2>/dev/null || true
    modprobe -r e1000e
    sleep 2
    modprobe e1000e
    sleep 3
    ip link set "$INTERFACE" up
    sleep 2

    # Re-add interface to bridge
    if brctl show "$BRIDGE" 2>/dev/null | grep -q "$BRIDGE"; then
        brctl addif "$BRIDGE" "$INTERFACE" 2>/dev/null || true
        log_info "Re-added $INTERFACE to bridge $BRIDGE"
    fi
}

# Main
main() {
    if ! detect_hang; then
        exit 0
    fi

    log_warn "Detected e1000e hardware unit hang on $INTERFACE"

    if ! check_rate_limit; then
        exit 1
    fi

    record_recovery

    # Step 1: Try soft reset
    soft_reset

    # Check if hang persists after soft reset
    if ! detect_hang; then
        log_info "Soft reset recovered $INTERFACE successfully"
        exit 0
    fi

    # Step 2: Try hard reset (module reload)
    hard_reset

    # Final check
    if detect_hang; then
        log_err "e1000e hang persists after module reload on $INTERFACE. Manual intervention required."
        exit 1
    fi

    log_info "Module reload recovered $INTERFACE successfully"
    exit 0
}

main
