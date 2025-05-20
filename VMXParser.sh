#!/bin/bash

SEARCH_DIR="${1:-.}"

echo "[i] Searching for .vmx files in: $SEARCH_DIR"
echo

find "$SEARCH_DIR" -type f -name "*.vmx" | while read -r vmx_file; do
    echo "=============================="
    echo "[i] File: $vmx_file"
    echo "=============================="

    grep -Ei '(^displayName|domain|user|autologin|iso|net|ethernet|admin|pass|desc|comment|annotation|host)' "$vmx_file" | grep -vi 'guestinfo.appinfo' | sed -E \
        -e 's/^(.*displayName)/Display Name: \1/i' \
        -e 's/^(.*domain)/Domain: \1/i' \
        -e 's/^(.*user)/User: \1/i' \
        -e 's/^(.*admin)/Admin: \1/i' \
        -e 's/^(.*autologin)/Autologin: \1/i' \
        -e 's/^(.*pass)/Password: \1/i' \
        -e 's/^(.*iso)/ISO: \1/i' \
        -e 's/^(.*ethernet|.*net)/Ethernet: \1/i' \
        -e 's/^(.*annotation|.*desc|.*comment)/Notes: \1/i'
    echo
done
