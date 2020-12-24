#Requires -version 7
param(
    [parameter(Position=0)]$registry
,[parameter(Position=1)]$repository = ""
,[parameter(Position=2)][STRING[]]$SQLtagNames = '2017-latest'
,[parameter(Position=3)][securestring]$SAPassword
,[parameter(Position=4)][bool]$isLatest = $true
,[parameter(Position=5)]$workingDir = (Split-Path $PSScriptRoot -parent)

)

Import-Module FC_Core, FC_Docker -Force -ErrorAction Stop -DisableNameChecking

# Param validation/defaults
if($null -eq $SAPassword){
    if ($null -ne [Environment]::GetEnvironmentVariable("SA_PASSWORD", "User")){
        Write-Host "Using the USER env variable"
        $SAPassword = [Environment]::GetEnvironmentVariable("SA_PASSWORD", "User")
    }
    if($null -eq $SAPassword){
        Write-Error "Setting unsecure default password for SA"
        $SAPassword = (ConvertTo-SecureString 'WeakP@ssword' -AsPlainText -Force)
    }
    if($null -eq $SAPassword){
        Write-Error "I don't know what to set for SAPassword!" -ErrorAction Stop
    }
}

# loop over the base sql tags. IE what sql server version/cu do you want?
foreach($SQLtagName in $SQLtagNames){
        Write-Log "SQLtagname: $sqltagName"
    $buildArgs = @{ 
        CD_SA_PASSWORD="$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SAPassword)))"; 
        IMAGE="mcr.microsoft.com/mssql/server:$SQLtagName";
}
    $imageName = "$((Split-Path $workingDir -Leaf).ToLower())_$SQLtagName"
    Invoke-DockerImageBuild  -registry $registry `
    -repository $repository `
    -imageName $imageName `
    -buildArgs $buildArgs `
    -isLatest $isLatest `
     -logLevel 'Debug' `
    -workingDir $workingDir
}
    