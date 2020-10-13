<#
    .Synopsis
      Simple script to make restoring the volumes from this docker-compose service from a network location easier
    .PARAMETER backupDir
      The local directory to copy the most recent backup into. This path cannot have spaces
    .PARAMETER archivePath
      The network (or other) location where the full list of backups are stored. 
#>
param($backupDir = "E:\CollectIt\dockerBackups",
$archivePath = "M:\Backups\Container Backups\factorio")
Import-Module FC_Log
$oldLocation = Get-Location
Set-Location $PSScriptRoot
$logLevel = 'Debug'
try{
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
    $options = "run --rm -v $($backupDir):/backup --entrypoint /bin/sh -v myfactorio_game_data:/factorio factoriotools/factorio -c `"cd /factorio && tar xvzf /backup/$($mostRecentBackupFile.Name) --strip 2 && rm /factorio/saves/_autosave1.zip`""
    Write-Log "docker options: $options"
    $return=Start-MyProcess -EXEPath "docker" -Options $options

     if ($logLevel -eq "Debug"){
        #Only show the stdout stream if we are in debugging logLevel
        $return.stdout
    }
    if (-not [string]::IsnullOrEmpty($return.stderr)){
        Write-Log "$($return.stderr)" Warning
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
