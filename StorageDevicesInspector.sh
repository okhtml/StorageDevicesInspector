#!/bin/bash
set -euo pipefail

# Initialize an empty array to store the results.
RESULTS=()
# Output file where the final JSON will be saved.
OUTPUT_FILE="StorageDevicesInfo.json"

# Function to convert bytes to gigabytes, with 2 decimal places.
bytes_to_gb() {
    awk -v bytes="$1" 'BEGIN { printf("%.2f", bytes/1024/1024/1024) }'
}

# Function to handle JSON string formatting:
# If the value is empty or "null", it returns a literal "null" in JSON format.
# Otherwise, it escapes the string and wraps it in double quotes for valid JSON.
json_str_or_null() {
    local val=$1
    
    if [[ -z "$val" || "$val" == "null" ]]; then
        echo "null"
    else
        printf '%s' "\"$(echo "$val" | sed 's/\\/\\\\/g; s/"/\\"/g')\""
    fi
}

# Function to gather information about a storage device.
gather_device_info() {
    local devicePath=$1
    local deviceType=$2

    # Get properties of the device using udevadm.
    properties=$(udevadm info --query=property --name="$devicePath" 2>/dev/null || echo "")

    # Extract specific device information from the properties.
    serialNumber=$(grep -m1 '^ID_SERIAL_SHORT=' <<< "$properties" | cut -d= -f2 || echo "")
    model=$(grep -m1 '^ID_MODEL=' <<< "$properties" | cut -d= -f2 || echo "")
    vendorID=$(grep -m1 '^ID_VENDOR_ID=' <<< "$properties" | cut -d= -f2 || echo "")
    productID=$(grep -m1 '^ID_MODEL_ID=' <<< "$properties" | cut -d= -f2 || echo "")

    # Get total device size in bytes and GB.
    totalSizeBytes=$(lsblk -bn -d -o SIZE "$devicePath")
    totalSizeGB=$(bytes_to_gb "$totalSizeBytes")

    # Get partitions of the device.
    partitions=$(lsblk -ln -o NAME,TYPE "$devicePath" | awk '$2=="part" {print $1}')

    # Initialize a JSON array for partition details.
    partitionsJson="["
    freeSpaceBytesSum=0
    first=1

    # Iterate over each partition to gather more info.
    for partition in $partitions; do
        local partitionPath="/dev/$partition"
        fileSystem=$(lsblk -no FSTYPE "$partitionPath" | xargs || echo "")
        volumeName=$(lsblk -no LABEL "$partitionPath" | xargs || echo "")
        mountPoint=$(lsblk -no MOUNTPOINT "$partitionPath" | xargs || echo "")

        # If partition is mounted, calculate its free space.
        if [[ -n "$mountPoint" ]]; then
            freeSpaceBytes=$(df --output=avail -B1 "$mountPoint" 2>/dev/null | tail -n1 | xargs || echo 0)
            freeSpaceBytesSum=$((freeSpaceBytesSum + freeSpaceBytes))
        fi

        # Handle JSON formatting for partitions (comma separation)
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

    # Convert the sum of free space to GB
    freeSpaceGB=$(bytes_to_gb "$freeSpaceBytesSum")

    # Add the gathered data into the results array in JSON format
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


# Loop over all block devices (e.g., /dev/sdx) to collect their info
for device in $(lsblk -dn -o NAME | grep -E '^[sv]d'); do
    devicePath="/dev/$device"
    bus=$(udevadm info --query=property --name="$devicePath" | grep -m1 '^ID_BUS=' |cut -d= -f2 || echo "")

    # Check if the device is a USB or Fixed Disk
    if [[ "$bus" == "usb" ]]; then
        gather_device_info "$devicePath" "USB"

    elif [[ "$bus" != "usb" ]]; then
        gather_device_info "$devicePath" "Fixed Disk"
    fi

done

# Format the collected results as a proper JSON array and save to the output file
{
    echo "["
    for i in "${!RESULTS[@]}"; do
        [[ $i -ne 0 ]] && echo ","
        echo "${RESULTS[$i]}"

    done

    echo "]"
} | jq --indent 4 '.' > "$OUTPUT_FILE"
