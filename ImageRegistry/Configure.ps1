#Requires -Version 7.0
# Generates a .env file for the containers, and a Corefile and db file for CoreDNS. It loads a config/config.json file to get the records that you have setup. 
param($RESTART_POLICY = 'always'
,$SQUID_HOSTNAME = ''
)

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

$GF_SECURITY_ADMIN_PASSWORD=$(generatePassword)

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

Remove-Item .env -Force -errorAction Ignore
"visible_hostname proxy.$GF_SECURITY_ADMIN_PASSWORD )
RESTART_POLICY=$RESTART_POLICY"`
| Add-Content -Path .env

Write-Host "configure"
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
$ARecords = $config.Records | where {$_.RecordType -eq "A"}
$ARecords
$ARecordString = ""
foreach ($record in $ARecords){
    $ARecordString += "$($record.Name) $($record.ZoneClass)  $($record.RecordType) $($record.IpAddress)
"
}
"$($SOARecord.Name) $($SOARecord.ZoneClass)  $($SOARecord.RecordType)   $($SOARecord.MNAME) $($SOARecord.RNAME) $($SOARecord.SERIAL)  $($SOARecord.REFRESH)  $($SOARecord.RETRY)  $($SOARecord.EXPIRE) $($SOARecord.TTL) 
$ARecordString
" | Set-Content -Path $mountPointPath/$($config.domain).db