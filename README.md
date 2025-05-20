## SMBScannerOpenShares.sh
This scans open shares from an unauthenticated perspective with a verbose output. Run the command with `bash SMBScannerOpenShares.sh <Targets File with IPs>`

## VMDK_Search.sh
This scans a folder recursively for VMDK files and attempts to extract credentials from VMDK's. Checks for SAM/Powershell/RDP. Mount the share, such as an NFS share, and run the command with `bash VMDK_Search.sh <Search Directory>`

## VMXParser.sh
This scans a folder recursively for VMX files and parses them to identify potentially sensitive information. Mount the share, such as an NFS share, and run the command with `bash VMXParser.sh <Search Directory>`

## NFS_VMX_VMDK_Sweeper.sh
This runs the VMDK_Search and VMXParser scripts against a base of NFS targetes. Provide a text file with IPs that have NFS shares and it will run against them. Run the command with `bash NFS_VMX_VMDK_Sweeper.sh <Targets File with NFS IPs>`

## NFS_VMX_Only_Sweeper.sh
This was a simple script to automount NFS shares and run the VMXParser against it. Provide a text file with IPs that have NFS shares and youre good. Run the command with `bash NFS_VMX_Only_Sweeper.sh <Targets File with NFS IPs>`
