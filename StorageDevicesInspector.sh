#!/bin/bash
set -euo pipefail

RESULTS=()
OUTPUT_FILE="StorageDevicesInfo.json"


bytes_to_gb() {
    awk -v bytes="$1" 'BEGIN { printf("%.2f", bytes/1024/1024/1024) }'
}


json_str_or_null() {
    local val=$1
    
    if [[ -z "$val" || "$val" == "null" ]]; then
        echo "null"
    else
        printf '%s' "\"$(echo "$val" | sed 's/\\/\\\\/g; s/"/\\"/g')\""
    fi
}


gather_device_info() {
    local devicePath=$1
    local deviceType=$2

    properties=$(udevadm info --query=property --name="$devicePath" 2>/dev/null || echo "")

    serialNumber=$(grep -m1 '^ID_SERIAL_SHORT=' <<< "$properties" | cut -d= -f2 || echo "")
    model=$(grep -m1 '^ID_MODEL=' <<< "$properties" | cut -d= -f2 || echo "")
    vendorID=$(grep -m1 '^ID_VENDOR_ID=' <<< "$properties" | cut -d= -f2 || echo "")
    productID=$(grep -m1 '^ID_MODEL_ID=' <<< "$properties" | cut -d= -f2 || echo "")

    totalSizeBytes=$(lsblk -bn -d -o SIZE "$devicePath")
    totalSizeGB=$(bytes_to_gb "$totalSizeBytes")

    partitions=$(lsblk -ln -o NAME,TYPE "$devicePath" | awk '$2=="part" {print $1}')

    partitionsJson="["
    freeSpaceBytesSum=0
    first=1

    for partition in $partitions; do
        local partitionPath="/dev/$partition"
        fileSystem=$(lsblk -no FSTYPE "$partitionPath" | xargs || echo "")
        volumeName=$(lsblk -no LABEL "$partitionPath" | xargs || echo "")
        mountPoint=$(lsblk -no MOUNTPOINT "$partitionPath" | xargs || echo "")

        if [[ -n "$mountPoint" ]]; then
            freeSpaceBytes=$(df --output=avail -B1 "$mountPoint" 2>/dev/null | tail -n1 | xargs || echo 0)
            freeSpaceBytesSum=$((freeSpaceBytesSum + freeSpaceBytes))
        fi

        if [[ $first -eq 0 ]]; then 
            partitionsJson+=","
        else
            first=0
        fi

        partitionsJson+="{
            \"Partition\": \"$partitionPath\",
            \"FileSystem\": $(json_str_or_null "$fileSystem"),
            \"VolumeName\": $(json_str_or_null "$volumeName"),
            \"MountPoint\": $(json_str_or_null "$mountPoint")
        }"

    done

    partitionsJson+="]"

    freeSpaceGB=$(bytes_to_gb "$freeSpaceBytesSum")

    RESULTS+=("{
        \"DeviceType\": \"$deviceType\",
        \"VendorID\": $(json_str_or_null "$vendorID"),
        \"ProductID\": $(json_str_or_null "$productID"),
        \"SerialNumber\": $(json_str_or_null "$serialNumber"),
        \"Model\": $(json_str_or_null "$model"),
        \"DriveLetter\": $(json_str_or_null "$devicePath"),
        \"TotalSizeGB\": \"$totalSizeGB\",
        \"TotalSizeBytes\": \"$totalSizeBytes\",
        \"FreeSpaceGB\": \"$freeSpaceGB\",
        \"FreeSpaceBytes\": \"$freeSpaceBytesSum\",
        \"Partitions\": $partitionsJson
    }")
}


for device in $(lsblk -dn -o NAME | grep -E '^[sv]d'); do
    devicePath="/dev/$device"
    bus=$(udevadm info --query=property --name="$devicePath" | grep -m1 '^ID_BUS=' |cut -d= -f2 || echo "")

    if [[ "$bus" == "usb" ]]; then
        gather_device_info "$devicePath" "USB"

    elif [[ "$bus" != "usb" ]]; then
        gather_device_info "$devicePath" "Fixed Disk"
    fi

done


{
    echo "["
    for i in "${!RESULTS[@]}"; do
        [[ $i -ne 0 ]] && echo ","
        echo "${RESULTS[$i]}"

    done

    echo "]"
} | jq --indent 4 '.' > "$OUTPUT_FILE"
