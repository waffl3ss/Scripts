#!/bin/bash

NFS_LIST="${1:-nfs_targets.txt}"
VMX_SCRIPT="./VMXParser.sh"
VMDK_SCRIPT="./VMDK_Search.sh"
MOUNT_BASE="/mnt/nfs_enum"
mkdir -p "$MOUNT_BASE"

echo "[i] Starting full NFS -> VMX + VMDK sweep"
echo "[i] NFS list: $NFS_LIST"
echo

INDEX=0

while IFS= read -r nfs; do
    [[ -z "$nfs" ]] && continue
    MOUNT_POINT="$MOUNT_BASE/share_$INDEX"
    mkdir -p "$MOUNT_POINT"

    echo "=============================="
    echo "[i] Mounting NFS: $nfs -> $MOUNT_POINT"
    sudo mount -t nfs -o nolock "$nfs" "$MOUNT_POINT"
    if [[ $? -ne 0 ]]; then
        echo "[!] Failed to mount $nfs"
        rm -rf "$MOUNT_POINT"
        ((INDEX++))
        continue
    fi

    echo "[+] Mounted. Running analysis..."

    echo "[1/2] VMXParser.sh..."
    bash "$VMX_SCRIPT" "$MOUNT_POINT" 2>/dev/null

    echo "[2/2] VMDK_Search.sh..."
    bash "$VMDK_SCRIPT" "$MOUNT_POINT" 2>/dev/null

    echo "[i] Unmounting $MOUNT_POINT"
    sudo umount "$MOUNT_POINT"
    rm -rf "$MOUNT_POINT"

    ((INDEX++))
    echo
done < "$NFS_LIST"
