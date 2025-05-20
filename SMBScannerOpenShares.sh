#!/bin/bash

if [[ -z "$1" || ! -f "$1" ]]; then
    echo "Usage: $0 <target_ip_file>"
    exit 1
fi

INPUT="$1"
echo "[i] Starting SMB read-access check using $INPUT..."

while IFS= read -r IP; do
    [[ -z "$IP" ]] && continue
    echo "[i] Scanning $IP"

    shares=$(smbclient -L "$IP" -N 2>/dev/null | awk '/Disk/ {print $1}' | grep -Ev '^(print\$|IPC\$|ADMIN\$)$')

    for SHARE in $shares; do
        echo "  [+] Found share: $SHARE"

        list_output=$(smbclient "//$IP/$SHARE" -N -c 'dir' 2>&1)
        if echo "$list_output" | grep -q '^  '; then
            echo "    [READABLE] Directory listing succeeded"
        else
            echo "    [NOT READABLE] Access denied or empty"
        fi
    done

    echo
done < "$INPUT"
