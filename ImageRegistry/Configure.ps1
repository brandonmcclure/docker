#Requires -Version 7.0
# Generates a .env file for the containers, and a Corefile and db file for CoreDNS. It loads a config/config.json file to get the records that you have setup. 
param($RESTART_POLICY = 'always',
$registryBasicAuthUsername = 'basicAuth',
[securestring]$registryBasicAuthPassword = (Convertto-SecureString 'basicAuth' -AsPlainText),
$REGISTRY_UI_URL = 'https://Registry.mcd.com:5000',
$REGISTRY_UI_VERIFY_TLS = 'false'
,$SQUID_HOSTNAME = '',
$caBasicAuthUsername = 'basicAuth',
[securestring]$caBasicAuthPassword = (Convertto-SecureString 'basicAuth' -AsPlainText),
$REGISTRY_DELETE_ENABLE = $True
,$localHostAddress = '192.168.0.2'
,$domain = '.mcd.com'
,[securestring]$GF_SECURITY_ADMIN_PASSWORD = (Convertto-SecureString 'badPassword' -AsPlainText) # leave empty to generate a random one
)

Import-Module powershell-yaml

$mountpointRoot = "./mountPoints"
$foldersToCreate = @(
    "$mountpointRoot/dnsmasq"
    ,"$mountpointRoot/ca"
    ,"$mountpointRoot/coredns"
    ,"$mountpointRoot/grafana"
    ,"$mountpointRoot/registry"
    ,"$mountpointRoot/registryUI"
    ,"$mountpointRoot/squid"
)

[Environment]::SetEnvironmentVariable("DOCKER_CA_AUTHUSER", $caBasicAuthUsername, "User")
[Environment]::SetEnvironmentVariable("DOCKER_CA_AUTHPASSWORD", ($caBasicAuthPassword | ConvertFrom-SecureString), "User")


foreach($f in $foldersToCreate){If(-not (Test-Path $f)){New-Item $f -Force -ItemType Directory}}
# Check for docker.crt, docker.key  and ca-bundle.crt in the /config/ca
If (-not (Test-Path ./mountPoints/ca/docker.crt)){
    Write-Error "Could not find a certificate signing cert at: ./mountPoints/ca/docker.crt" -ErrorAction Stop
}
If (-not (Test-Path ./mountPoints/ca/docker.key)){
    Write-Error "Could not find a certificate signing key at: ./mountPoints/ca/docker.key" -ErrorAction Stop
}
If (-not (Test-Path ./mountPoints/ca/ca-bundle.crt)){
    Write-Error "Could not find a ca bundle at: ./mountPoints/ca/ca-bundle.crt" -ErrorAction Stop
}

# Create Secure Passwords in the config
function generatePassword() {
    
    function Get-RandomCharacters($length, $characters) { 
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
    $private:ofs="" 
    return [String]$characters[$random]
}
    function Scramble-String([string]$inputString){     
        $characterArray = $inputString.ToCharArray()   
        $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
        $outputString = -join $scrambledStringArray
        return $outputString 
    }

    $password = Get-RandomCharacters -length 16 -characters 'abcdefghiklmnoprstuvwxyzABCDEFGHKLMNOPRSTUVWXYZ1234567890!-_'
    
   Write-Output (Scramble-String($password) | ConvertTo-SecureString -AsPlainText -Force)
}


if([string]::IsNullOrEmpty($GF_SECURITY_ADMIN_PASSWORD)){
    $GF_SECURITY_ADMIN_PASSWORD=$(generatePassword)
}

function replaceWith{
    
    [cmdletbinding()]
  param(
      [parameter(ValueFromPipeline)]
      $string,
  $find = 'foo',
  $replace = 'bar'
  )
  PROCESS {
      $outVal = $string -replace $find, $replace
      Write-Output $outVal
  }
  }

  
if([string]::IsNullOrEmpty($registryBasicAuthUsername)){
    [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSERNAME", $registryBasicAuthUsername, "Process")
}
if([string]::IsNullOrEmpty($registryBasicAuthPassword)){
    $registryBasicAuthPassword = $(generatePassword)
    Write-Host "Generated random password for registry basic auth password: $registryBasicAuthPassword"
    [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", $registryBasicAuthPassword, "Process")
}
if([string]::IsNullOrEmpty($registryBasicAuthUsername)){
    [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSERNAME", $registryBasicAuthUsername, "Process")
}
if([string]::IsNullOrEmpty($registryBasicAuthPassword)){
    $registryBasicAuthPassword = $(generatePassword)
    Write-Host "Generated random password for registry basic auth password: $registryBasicAuthPassword"
    [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", $registryBasicAuthPassword, "Process")
}
else{
    [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", $registryBasicAuthUsername, "Process")
}

Write-Host "Setting up the Registry config file"
Remove-Item -Path ./mountPoints/registry/config.yml -ErrorAction Ignore
$registryConfig_yaml = Get-Content ./mountPoints/registry/config.yml.example -Raw
$config = ConvertFrom-Yaml $registryConfig_yaml

if (-not [string]::IsNullOrEmpty($REGISTRY_DELETE_ENABLE)){
    $config.Delete.enabled = $REGISTRY_DELETE_ENABLE
    
}
if (-not [string]::IsNullOrEmpty($REGISTRY_UI_URL)){
    $config.http.host = $REGISTRY_UI_URL
    
}

(ConvertTo-Yaml -Data $config) `
-replace "(version: [0-9]+?\.[0-9]{1}).+","`$1"`
 | Set-Content -path ./mountPoints/registry/config.yml -Force

 Write-Host "Setting up the RegistryMirror config file"
Remove-Item -Path ./mountPoints/registryMirror/config.yml -ErrorAction Ignore
$registryMirrorConfig_yaml = Get-Content ./mountPoints/registryMirror/config.yml.example -Raw
$config = ConvertFrom-Yaml $registryMirrorConfig_yaml

if (-not [string]::IsNullOrEmpty($REGISTRY_DELETE_ENABLE)){
    $config.Delete.enabled = $REGISTRY_DELETE_ENABLE
    
}

(ConvertTo-Yaml -Data $config) `
-replace "(version: [0-9]+?\.[0-9]{1}).+","`$1"`
 | Set-Content -path ./mountPoints/registryMirror/config.yml -Force

Write-Host "Setting up the RegistryUI config file"
Remove-Item -Path ./mountPoints/registryUI/config.yml -ErrorAction Ignore
$registryUIConfig = Get-Content ./mountPoints/registryUI/config.yml.example
$registryUIConfig `
| foreach-object{if (-not [string]::IsNullOrEmpty($registryBasicAuthUsername)){$_ |replaceWith -find "registry_username: basicAuth" -replace "registry_username: $registryBasicAuthUsername"}} `
| foreach-object{if (-not [string]::IsNullOrEmpty($registryBasicAuthPassword)){$_ | replaceWith -find "registry_password: basicAuth" -replace "registry_password: $(ConvertFrom-SecureString $registryBasicAuthPassword -AsPlainText  )"}} `
| foreach-object{if (-not [string]::IsNullOrEmpty($REGISTRY_UI_URL)){$_ |replaceWith -find "registry_url: https://Registry:5000" -replace "registry_url: $REGISTRY_UI_URL"}} `
| foreach-object{if (-not [string]::IsNullOrEmpty($REGISTRY_UI_VERIFY_TLS)){$_ |replaceWith -find "verify_tls: true" -replace "verify_tls: $REGISTRY_UI_VERIFY_TLS"}} `
| Add-Content -Path ./mountPoints/registryUI/config.yml -Force
Remove-Item .env -Force -errorAction Ignore
"visible_hostname proxy.$GF_SECURITY_ADMIN_PASSWORD )
RESTART_POLICY=$RESTART_POLICY"`
| Add-Content -Path .env

Write-Host "configure .env file"
Remove-Item .env -Force -errorAction Ignore
"GF_SECURITY_ADMIN_PASSWORD=$(ConvertFrom-SecureString $GF_SECURITY_ADMIN_PASSWORD -AsPlainText  )
RESTART_POLICY=$RESTART_POLICY"`
| Add-Content -Path .env

Write-Host "Generating CoreDNS Corefile and db"
$config = Get-Content ./config/config.json | convertfrom-json

$mountPointPath = "./Mountpoints/coredns"

Remove-Item -Path $mountPointPath/Corefile -Force -errorAction Ignore 

if (-not (Test-Path "$mountPointPath/Corefile")){
    New-Item "$mountPointPath/Corefile" -type File -Force -ErrorAction Stop
}
".:53 {
    forward $($config.forward -join " " )
    log
    errors
}

$($config.domain):53 {
    file /root/$($config.domain).db
    log
    errors
    health :5353
    prometheus :9253
}" | Set-Content -Path $mountPointPath/Corefile

Remove-Item -Path $mountPointPath/$($config.domain).db -Force -errorAction Ignore 
$SOARecord = $config.Records | where {$_.RecordType -eq "SOA"}
Write-Log "Creating $($SOARecord | Measure-Object | Select -expandproperty count) SOARecord records" Verbose
$ARecords = $config.Records | where {$_.RecordType -eq "A"}
Write-Log "Creating $($ARecords | Measure-Object | Select -expandproperty count) A records" Verbose
$ARecordString = ""
foreach ($record in $ARecords){
    $ARecordString += "$($record.Name) $($record.ZoneClass)  $($record.RecordType) $(if(-not[string]::IsNullOrEmpty($localHostAddress) -and $record.IpAddress -eq 'localhost'){$localHostAddress}else{$record.IpAddress})
"
}
"$($SOARecord.Name) $($SOARecord.ZoneClass)  $($SOARecord.RecordType)   $($SOARecord.MNAME) $($SOARecord.RNAME) $($SOARecord.SERIAL)  $($SOARecord.REFRESH)  $($SOARecord.RETRY)  $($SOARecord.EXPIRE) $($SOARecord.TTL) 
$ARecordString" | Set-Content -Path $mountPointPath/$($config.domain).db
