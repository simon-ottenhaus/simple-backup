# script to back up each sub-directory as a separate 7z file

# read Config from backup.jsonc, in the same directory as this script
# example backup.jsonc:
# {
#     "source": "C:\\data\\Photos",
#     "target": "D:\\Photos",
#     "path7z": "C:\\Program Files\\7-Zip\\7z.exe"
# }

Get-Content backup.json -Raw | Write-Host

$json = Get-Content backup.json -Raw | ConvertFrom-Json
$SOURCE_DIR = $json.source
$TARGET_DIR = $json.target
$7z = $json.path7z




# function to test if a source/target directory exists and if 7z.exe exists
function test-7z {
    param (
        [string]$7z,
        [string]$SOURCE_DIR,
        [string]$TARGET_DIR
    )
    # test if 7z.exe exists: if not, exit
    if (-not (Test-Path $7z)) {
        Write-Host "7z.exe not found at $7z"
        exit
    }
    # test if source directory exists: if not, exit
    if (-not (Test-Path $SOURCE_DIR)) {
        Write-Host "Source directory not found at $SOURCE_DIR"
        exit
    }
    # test if target directory exists: if not, exit
    if (-not (Test-Path $TARGET_DIR)) {
        Write-Host "Target directory not found at $TARGET_DIR"
        exit
    }
}

function Get-Expected-7z-File-Name {
    param (
        [string]$subdir,
        [string]$TARGET_DIR
    )
    # get the full path of the 7z file
    $7zfile = "$TARGET_DIR\$subdir.7z"
    # return the 7z file name
    return $7zfile
}

function Get-Backup-Exists {
    param (
        [string]$7zfile
    )
    # check if the 7z file exists, or if .7z.001 exists, return true
    if (Test-Path $7zfile) {
        return $true
    }
    if (Test-Path "$7zfile.001") {
        return $true
    }
    # otherwise return false
    return $false
}

function Get-Dir-Size {
    param (
        [string]$dir
    )
    # get the size of the directory
    $size = (Get-ChildItem $dir -Recurse | Measure-Object -Property Length -Sum).Sum
    # return the size
    return $size
}

function Get-Backup-Size {
    param (
        [string]$7zfile
    )
    # $7zfile is a path to a 7z file ".7z"
    # find all files with the same name, but with ".7z.001", ".7z.002", etc.
    $size = (Get-ChildItem $7zfile* | Measure-Object -Property Length -Sum).Sum
    # return the size
    return $size
}

function Get-Human-Readable-Size {
    param (
        [float]$size
    )
    # convert the size to a human readable format: kb, mb, gb, tb
    $sizes = "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"
    $i = 0
    while ($size -gt 1024) {
        $size = $size / 1024.0
        $i++
    }
    #$size = [math]::Round($size, 2)
    $unit = $sizes[$i]
    # format size with 2 decimals
    return "{0:N2} {1}" -f $size, $unit
}

# main back up function
function Backup-With-7z {
    param (
        [string]$7z,
        [string]$SOURCE_DIR,
        [string]$TARGET_DIR
    )
    # test arguments
    test-7z $7z $SOURCE_DIR $TARGET_DIR
    
    # get all sub-directories in source directory
    $subdirs = Get-ChildItem $SOURCE_DIR -Directory


    # list of already backed up directories
    $backed_up = @()

    # list of commands to run
    $commands = @()


    # loop through each sub-directory
    foreach ($subdir in $subdirs) {
        Write-Host "subdir: $subdir"
        # get the full path of the 7z file
        $7zfile = Get-Expected-7z-File-Name $subdir $TARGET_DIR
        # print the 7z file name
        Write-Host "7z file: $7zfile"
        # check if the 7z file exists
        $backup_exists = Get-Backup-Exists $7zfile
        # if the 7z file exists, add the sub-directory to the list of backed up directories
        # else create the command to back up the sub-directory
        if ($backup_exists) {
            $backed_up += $subdir
        }
        else {
            # create 7z archive, no compression, 4GB volumes
            $7z_cmd = "'$7z' a -t7z -mx0 -v4g '$7zfile' '$SOURCE_DIR\$subdir'"
            # add the command to the list of commands
            $commands += $7z_cmd
        }
    }

    # print status: 
    # already backed up: N
    # - <path>
    # to be backed up: N
    # - <command>
    Write-Host "Status:"
    Write-Host "already backed up: $($backed_up.Count) (size / backup size)"
    foreach ($subdir in $backed_up) {
        $size = Get-Dir-Size $subdir
        $size = Get-Human-Readable-Size $size
        $7zfile = Get-Expected-7z-File-Name $subdir $TARGET_DIR
        $size2 = Get-Backup-Size $7zfile
        $size2 = Get-Human-Readable-Size $size2
        Write-Host "- $subdir ($size / $size2)"
    }
    Write-Host "to be backed up: $($commands.Count)"
    foreach ($cmd in $commands) {
        $size = Get-Dir-Size $cmd.Split("'")[5]
        # Write-Host "size: $size"
        $size = Get-Human-Readable-Size $size
        Write-Host "- ($size) $cmd"
    }

    # check if there are any commands to run, if not, exit
    if ($commands.Count -eq 0) {
        Write-Host "Nothing to do"
        exit
    }


    # ask for confirmation
    $confirmation = Read-Host "Continue? (y/n)"
    if ($confirmation -ne "y") {
        exit
    }

    # run the commands
    foreach ($cmd in $commands) {
        Write-Host "Running: $cmd"
        Invoke-Expression "& $cmd"
    }

    
}

# call the main function
Backup-With-7z $7z $SOURCE_DIR $TARGET_DIR
