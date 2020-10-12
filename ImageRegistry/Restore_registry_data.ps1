<#
    .Synopsis
      Simple script to make restoring the volumes from this docker-compose service from a network location easier
    .PARAMETER backupDir
      The local directory to copy the most recent backup into. This path cannot have spaces
    .PARAMETER archivePath
      The network (or other) location where the full list of backups are stored. 
#>
param($backupDir = "",
$archivePath = "")
Import-Module FC_Log
$oldLocation = Get-Location
Set-Location $PSScriptRoot
$logLevel = 'Debug'
try{
    $
    If(-not (Test-Path $backupDir)){
        New-Item -Path $backupDir -ItemType Directory
    }
    $mostRecentBackupFile = Get-ChildItem $archivePath | where {$_.extension -eq ".gz"} | sort LastWriteTime -Descending | select -first 1
   
    if(-not (Test-Path $backupDir/$($mostRecentBackupFile.Name))){
        Write-Log "Copying backup to local device"
        Copy-Item $mostRecentBackupFile.FullName $backupDir/$($mostRecentBackupFile.Name)
    }
    
    Write-Log "Restoring the $($mostRecentBackupFile.Name) backup with a size of $($mostRecentBackupFile.Length /1Gb) GB"

    docker-compose up -d --build; docker-compose down
    $options = "run --rm -v $($backupDir):/backup -v imageregistry_registry_data:/var/lib/registry registry:2.7 /bin/sh -c `"cd /var/lib/registry && tar xvzf /backup/$($mostRecentBackupFile.Name) --strip 2`""
    Write-Log "docker options: $options"
    $return=Start-MyProcess -EXEPath "docker" -Options $options

     if ($logLevel -eq "Debug"){
        #Only show the stdout stream if we are in debugging logLevel
        $return.stdout
    }
    if (-not [string]::IsnullOrEmpty($return.sterr)){
        Write-Log "$($return.sterr)" Warning
        Write-Log "There was an error of some type. See warning above for more info" Error
    }

    Get-ChildItem $backupDir | sort LastWriteTime -Descending | select -skip 1 | remove-item 
}
catch{
    throw
}
finally{
    Set-Location $oldLocation
}
