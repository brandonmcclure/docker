<#
    .Synopsis
      Simple script to make backing up the volumes from this docker-compose service to a network location easier

    .PARAMETER archivePath
      The network (or other) location where the full list of backups are stored. 
#>
param(
$archivePath = "M:\Backups\Container Backups\factorio",
$backupContainerName = "game_backup",
$volumeName = "game_data"
)

if(-not (Test-Path $archivePath)){
    New-Item -Path $archivePath -ItemType Directory -Force
}
$oldLocation = Get-Location
Set-Location $PSScriptRoot
try{
    docker-compose exec $backupContainerName ./backup.sh

    $backupFiles = Get-ChildItem $PSScriptRoot\backups\$volumeName\ | where {$_.extension -eq ".gz"}
    $mostRecentBackupFile = $backupFiles | sort LastWriteTime -Descending | select -first 1
    Copy-item $mostRecentBackupFile.FullName $archivePath
}
catch{
    throw
}
finally{
    Set-Location $oldLocation
}