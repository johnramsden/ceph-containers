#!/bin/bash

set -xeEo pipefail

BLOCK=$(sudo lsblk --paths | awk '/14G/ || /64G/ {print $1}' | head -1)

function use_local_disk() {
    BLOCK_DATA_PART=${BLOCK}1
    sudo dmsetup version || true
    sudo swapoff --all --verbose
    if mountpoint -q /mnt; then
        sudo umount /mnt
        sudo wipefs --all --force "$BLOCK_DATA_PART"
    else
        sudo sgdisk --zap-all -- "${BLOCK}"
        sudo dd if=/dev/zero of="${BLOCK}" bs=1M count=10 oflag=direct,dsync
        sudo parted -s "${BLOCK}" mklabel gpt
    fi
    sudo lsblk
}

function create_partitions_for_osds() {
    rook/tests/scripts/create-bluestore-partitions.sh --disk "$BLOCK" --osd-count 2
    sudo lsblk
}

FUNCTION="$1"
shift
$FUNCTION "$@"
