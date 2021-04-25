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
,[Parameter(Position=0,mandatory=$true)]$localHostAddress = ''
,[Parameter(Position=1,mandatory=$true)]$domain = ''
,[securestring]$GF_SECURITY_ADMIN_PASSWORD = (Convertto-SecureString 'badPassword' -AsPlainText) # leave empty to generate a random one
,[string] $VSCode_TZ = 'Americas\Denver'
,$ldapOrg = ""
,[securestring]$LDAPAdminPassword = $null
)

Import-Module powershell-yaml,FC_Log,FC_Core -force -ErrorAction Stop

$mountpointRoot = "./mountPoints"
$foldersToCreate = @(
    "$mountpointRoot/dnsmasq"
    ,"$mountpointRoot/ca"
    ,"$mountpointRoot/coredns"
    ,"$mountpointRoot/grafana"
    ,"$mountpointRoot/registry"
    ,"$mountpointRoot/registryUI"
    ,"$mountpointRoot/squid"
	,,"$mountpointRoot/ingress"
)

[Environment]::SetEnvironmentVariable("DOCKER_CA_AUTHUSER", $caBasicAuthUsername, "User")
[Environment]::SetEnvironmentVariable("DOCKER_CA_AUTHPASSWORD", ($caBasicAuthPassword | ConvertFrom-SecureString), "User")
[Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSER", $registryBasicAuthUsername, "User")
[Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", ($registryBasicAuthPassword | ConvertFrom-SecureString), "User")

foreach($f in $foldersToCreate){If(-not (Test-Path $f)){New-Item $f -Force -ItemType Directory}}
# Check for docker.crt, docker.key  and ca-bundle.crt in the /config/ca
If (-not (Test-Path $mountpointRoot/ca/docker.crt)){
    Write-Error "Could not find a certificate signing cert at: $mountpointRoot/ca/docker.crt" -ErrorAction Stop
}
If (-not (Test-Path $mountpointRoot/ca/docker.key)){
    Write-Error "Could not find a certificate signing key at: $mountpointRoot/ca/docker.key" -ErrorAction Stop
}
If (-not (Test-Path $mountpointRoot/ca/ca-bundle.crt)){
    Write-Error "Could not find a ca bundle at: $mountpointRoot/ca/ca-bundle.crt" -ErrorAction Stop
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
if([string]::IsNullOrEmpty($LDAPAdminPassword)){
    $LDAPAdminPassword=$(generatePassword)
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
    [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSERNAME", $registryBasicAuthUsername, "User")
}
if([string]::IsNullOrEmpty($registryBasicAuthPassword)){
    $registryBasicAuthPassword = $(generatePassword)
    Write-Host "Generated random password for registry basic auth password: $registryBasicAuthPassword"
    [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", $registryBasicAuthPassword, "User")
}
if([string]::IsNullOrEmpty($registryBasicAuthUsername)){
    [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHUSERNAME", $registryBasicAuthUsername, "User")
}
if([string]::IsNullOrEmpty($registryBasicAuthPassword)){
    $registryBasicAuthPassword = $(generatePassword)
    Write-Host "Generated random password for registry basic auth password: $registryBasicAuthPassword"
    [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", $registryBasicAuthPassword, "User")
}
else{
    [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY_AUTHPASSWORD", $registryBasicAuthUsername, "User")
}

Write-Host "Setting up the Registry config file"
Remove-Item -Path $mountpointRoot/registry/config.yml -ErrorAction Ignore
$registryConfig_yaml = Get-Content $mountpointRoot/registry/config.yml.example -Raw
$config = ConvertFrom-Yaml $registryConfig_yaml

if (-not [string]::IsNullOrEmpty($REGISTRY_DELETE_ENABLE)){
    $config.Delete.enabled = $REGISTRY_DELETE_ENABLE
    
}
if (-not [string]::IsNullOrEmpty($REGISTRY_UI_URL)){
    $config.http.host = $REGISTRY_UI_URL
    
}

(ConvertTo-Yaml -Data $config) `
-replace "(version: [0-9]+?\.[0-9]{1}).+","`$1"`
 | Set-Content -path $mountpointRoot/registry/config.yml -Force

 Write-Host "Setting up the RegistryMirror config file"
Remove-Item -Path $mountpointRoot/registryMirror/config.yml -ErrorAction Ignore
$registryMirrorConfig_yaml = Get-Content $mountpointRoot/registryMirror/config.yml.example -Raw
$config = ConvertFrom-Yaml $registryMirrorConfig_yaml

if (-not [string]::IsNullOrEmpty($REGISTRY_DELETE_ENABLE)){
    $config.Delete.enabled = $REGISTRY_DELETE_ENABLE
    
}

(ConvertTo-Yaml -Data $config) `
-replace "(version: [0-9]+?\.[0-9]{1}).+","`$1"`
 | Set-Content -path $mountpointRoot/registryMirror/config.yml -Force

Write-Host "Setting up the RegistryUI config file"
Remove-Item -Path $mountpointRoot/registryUI/config.yml -ErrorAction Ignore
$registryUIConfig = Get-Content $mountpointRoot/registryUI/config.yml.example
$registryUIConfig `
| foreach-object{if (-not [string]::IsNullOrEmpty($registryBasicAuthUsername)){$_ |replaceWith -find "registry_username: basicAuth" -replace "registry_username: $registryBasicAuthUsername"}} `
| foreach-object{if (-not [string]::IsNullOrEmpty($registryBasicAuthPassword)){$_ | replaceWith -find "registry_password: basicAuth" -replace "registry_password: $(ConvertFrom-SecureString $registryBasicAuthPassword -AsPlainText  )"}} `
| foreach-object{if (-not [string]::IsNullOrEmpty($REGISTRY_UI_URL)){$_ |replaceWith -find "registry_url: https://Registry:5000" -replace "registry_url: $REGISTRY_UI_URL"}} `
| foreach-object{if (-not [string]::IsNullOrEmpty($REGISTRY_UI_VERIFY_TLS)){$_ |replaceWith -find "verify_tls: true" -replace "verify_tls: $REGISTRY_UI_VERIFY_TLS"}} `
| Add-Content -Path $mountpointRoot/registryUI/config.yml -Force

Write-Host "configure grafana.env file"
Remove-Item grafana.env -Force -errorAction Ignore
"GF_SECURITY_ADMIN_PASSWORD=$(ConvertFrom-SecureString $GF_SECURITY_ADMIN_PASSWORD -AsPlainText  )
RESTART_POLICY=$RESTART_POLICY"`
| Add-Content -Path grafana.env

Write-Host "configure registry.env file"
Remove-Item registry.env -Force -errorAction Ignore
"DOCKER_REGISTRY_AUTHUSER=$registryBasicAuthUsername
DOCKER_REGISTRY_AUTHPASSWORD=$(ConvertFrom-SecureString $registryBasicAuthPassword -AsPlainText  )
RESTART_POLICY=$RESTART_POLICY
REGISTRY_HTTP_HOST=https://localhost:5000"`
| Add-Content -Path registry.env

Write-Host "configure ca.env file"
Remove-Item ca.env -Force -errorAction Ignore
"DOCKER_CA_AUTHUSER=$caBasicAuthUsername
DOCKER_CA_AUTHPASSWORD=$(ConvertFrom-SecureString $caBasicAuthPassword -AsPlainText  )
RESTART_POLICY=$RESTART_POLICY"`
| Add-Content -Path ca.env

Write-Host "configure vscode.env file"
Remove-Item vscode.env -Force -errorAction Ignore
"TZ=$VSCode_TZ
PROXY_DOMAIN=vscode.$domain
"`
| Add-Content -Path vscode.env
Write-Host "configure elastic.env file"
Remove-Item .env -Force -errorAction Ignore
""`
| Add-Content -Path elastic.env

Write-Host "configure openldap.env file"
$baseDN = ""
 foreach($j in ($domain -split "\.")){
	if([string]::IsNullOrEmpty($baseDN)){
		 $baseDN = "dc=$j"
	}else{
		 $baseDN = "$baseDN,dc=$j"
	}
}

Remove-Item openldap.env -Force -errorAction Ignore
"LDAP_ORGANISATION=$ldapOrg
ORGANISATION_NAME=$ldapOrg
LDAP_DOMAIN=$domain
LDAP_RFC2307BIS_SCHEMA=true
LDAP_REMOVE_CONFIG_AFTER_SETUP=true
LDAP_ADMIN_PASSWORD=$(ConvertFrom-SecureString $LDAPAdminPassword -AsPlainText  )
SERVER_HOSTNAME=ldap.$domain
LDAP_URI=ldap://ldap.$domain
LDAP_BASE_DN=$baseDN
LDAP_REQUIRE_STARTTLS=FALSE
LDAP_ADMINS_GROUP=admins
LDAP_ADMIN_BIND_DN=cn=admin,$baseDN
LDAP_ADMIN_BIND_PWD=$(ConvertFrom-SecureString $LDAPAdminPassword -AsPlainText  )
LDAP_IGNORE_CERT_ERRORS=true
EMAIL_DOMAIN=$domain
"`
| Add-Content -Path openldap.env

Write-Host "Generating CoreDNS Corefile and db"
$config = Get-Content ./config/config.json | convertfrom-json

$mountPointPath = "$mountpointRoot/coredns"

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
    $ARecordString += "$($record.Name).$domain. $($record.ZoneClass)  $($record.RecordType) $(if(-not[string]::IsNullOrEmpty($localHostAddress) -and $record.IpAddress -eq 'localhost'){$localHostAddress}else{$record.IpAddress})
"
}


    $SOAString = "$domain. IN SOA $($config.DNS.MNAME)$domain. $($config.DNS.RNAME)$domain $($config.DNS.SERIAL) $($config.DNS.REFRESH) $($config.DNS.RETRY) $($config.DNS.EXPIRE) $($config.DNS.TTL)
"


"$SOAString$ARecordString" | Set-Content -Path $mountPointPath/$($config.domain).db

#Update Prometheus.yml
$promConfig = Get-Content $mountpointRoot/prometheus/prometheus.yml 

$promConfig |replaceWith -find ".example.com" -replace ".$domain" `
| Set-Content -Path $mountpointRoot/prometheus/prometheus.yml 

# Create certgetter
.\BuildTools\setup.certgetter.ps1 -config $config -domain $domain

# Create Ingress
$ingress = .\BuildTools\setup.ingress.ps1 -config $config -domain $domain
Set-Content -Path $mountpointRoot/ingress/nginx.conf -Value $ingress
Invoke-UnixLineEndings -directory $PSScriptRoot -excludeExtensions @("mdb","MYI","MYD") -excludeFilter @("**\mointPoints\db*")