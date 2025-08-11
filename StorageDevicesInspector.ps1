# Function to convert bytes to gigabytes, rounding the result to two decimal places
function Convert-BytesToGB {
    param ($bytes)
    return [math]::Round($bytes / 1GB, 2)
}

# Initialize an empty list to store the results
$results = [System.Collections.Generic.List[PSObject]]::new()

# Get all USB devices with an interface type of "USB"
$usbDevices = @(Get-WmiObject -Class Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB"})
# Get all USB hubs with the caption containing "Mass Storage"
$usbHubs = @(Get-WmiObject Win32_USBHub | Where-Object {$_.Caption -like "*USB*" -and $_.Caption -like "*Mass Storage*"} | Select-Object __PATH)

# Iterate over each USB hub and its corresponding device
for ($i = 0; $i -lt $usbHubs.Count; $i++) {
    $hub = $usbHubs[$i] # Current USB hub
    $usbDevice = $usbDevices[$i] # Corresponding USB device

    # Get the partition associated with the current USB device
    $partition = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($usbDevice.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
    # Get the logical disks (Volumes) associated with the partition
    $logicalDisks = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"

    # Iterate over each logical disk (Volume) for the current device 
    foreach ($logicalDisk in $logicalDisks) {
        $vendorID = $productID = $null

        # Extract VendorID and ProductID from the USB hub path (if available)
        if ($hub.__Path -match "VID_([0-9A-F]{4})&PID_([0-9A-F]{4})") {
            $vendorID = $matches[1]
            $productID = $matches[2]
        }

        # Extract the serial number form the USB device's PNPDevicesID
        $serialNumber = if ( $usbDevice.PNPDeviceID -match "\\\\([^\\\\]+)$" ) { $matches[1].Trim() } else { $usbDevice.PNPDeviceID }

        # Add a new entry to the results list for the current logical disk (Volume)
        $results.Add(
            [PSCustomObject]@{
                DeviceType     = "USB"
                VendorID       = $vendorID
                ProductID      = $productID
                SerialNumber   = $serialNumber
                Model          = $usbDevice.Model.Trim()
                Caption        = $usbDevice.Caption
                DriveLetter    = $logicalDisk.DeviceID
                VolumeName     = $logicalDisk.VolumeName
                FileSystem     = $logicalDisk.FileSystem
                PartitionType  = $partition.Type
                DeviceIndex    = $usbDevice.Index
                TotalSizeGB      = Convert-BytesToGB $logicalDisk.Size
                TotalSizeBytes = $logicalDisk.Size
                FreeSpaceGB      = Convert-BytesToGB $logicalDisk.FreeSpace
                FreeSpaceBytes = $logicalDisk.FreeSpace
                Status         = $usbDevice.Status
                HealthStatus   = $null
            }
        )

    }   
}

# Get all non-USB drives (e.g., HDDs, SSDs, etc...)
$disks = Get-CimInstance -ClassName Win32_DiskDrive -Filter "InterfaceType != 'USB'"

# Iterate over each non-USB disk drives
foreach ($disk in $disks) {
    # Get partitions associated with the current disk
    $partitions = Get-CimAssociatedInstance -InputObject $disk -ResultClassName Win32_DiskPartition -ErrorAction SilentlyContinue

    # Iterate over each partition of the current disk
    foreach ($partition in $partitions) {
        try {

            # Get the logical disks (Volumes) associated with the current partition
            $logicalDisks = Get-CimAssociatedInstance -InputObject $partition -ResultClassName Win32_LogicalDisk -ErrorAction SilentlyContinue
            
            # If logical disks exist for the partition, process each
            if ($logicalDisks) {
                foreach ($logicalDisk in $logicalDisks) {
                    
                    # Extract the drive letter from the logical disk's DeviceID
                    $driveLetter = ($logicalDisk.DeviceID -replace ':', '')
                    # Get volume details for the drive letter (if available)
                    $volume = if ($logicalDisk.DeviceID) { Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue }
                    
                    # Add a new entry for the logical disk (volume) to the results list
                    $results.Add(
                        [PSCustomObject]@{
                            DeviceType     = "Fixed Disk"
                            VendorID       = $null
                            ProductID      = $null
                            SerialNumber   = ($disk.SerialNumber -replace '[^a-zA-Z0-9]', '').Trim()
                            Model          = $disk.Model.Trim()
                            Caption        = $disk.Caption
                            DriveLetter    = $logicalDisk.DeviceID
                            VolumeName     = if ($volume) { $volume.FileSystemLabel } else { $logicalDisk.VolumeName }
                            FileSystem     = $logicalDisk.FileSystem
                            PartitionType  = $partition.Type
                            MountPoint     = if ($volume) { $volume.path} else { $logicalDisk.DeviceID}
                            TotalSizeGB    = Convert-BytesToGB $logicalDisk.Size
                            TotalSizeBytes = $logicalDisk.Size
                            FreeSpaceGB    = Convert-BytesToGB $logicalDisk.FreeSpace
                            FreeSpaceBytes = $logicalDisk.FreeSpace
                            status         = $disk.Status
                            HealthStatus   = if ($volume) { $volume.HealthStatus } else { $null }
                            BootPartition  = $partition.BootPartition
                        }
                    )

                }
            } else {
                # If no logical disks exist for the partition, add a minimal entry
                $results.Add(
                    [PSCustomObject]@{
                        DeviceType     = "Fixed Disk"
                        VendorID       = $null
                        ProductID      = $null
                        SerialNumber   = ($disk.SerialNumber -replace '[^a-zA-Z0-9]', '').Trim()
                        Model          = $disk.Model.Trim()
                        Caption        = $disk.Caption
                        DriveLetter    = $null
                        VolumeName     = $null
                        FileSystem     = $null
                        PartitionType  = $partition.Type
                        MountPoint     = $null
                        TotalSizeGB    = Convert-BytesToGB $partition.Size
                        TotalSizeBytes = $partition.Size
                        FreeSpaceGB    = $null
                        FreeSpaceBytes = $null
                        status         = $disk.Status
                        HealthStatus   = $null
                        BootPartition  = $partition.BootPartition
                    }
                )
            }

        } catch { }
    }
}

# Convert the results array to JSON format with a depth of 4 (to include nested objects)
# Then, save the JSON output to a file named "StorageDevicesInfo.json" with UTF-8 encoding
$results | ConvertTo-Json -Depth 4 | Out-File "StorageDevicesInfo.json" -Encoding utf8
