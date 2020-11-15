$config = Get-Content ../config/config.json | convertfrom-json
$ARecords = $config.Records | where {$_.RecordType -eq "A"}

$PSDefaultParameterValues['Test-NetConnection:InformationLevel'] = 'Quiet'
$objs = @()
foreach ($aRecord in $ARecords){
    $obj = New-Object psobject -Property @{
        name=$aRecord.Name 
        ipaddress=$aRecord.IpAddress
        pingResult = @()
    }
    $obj.pingResult = Test-NetConnection -ComputerName $aRecord.Name 
    $objs += $obj
}

if (($objs  | where {$_.pingResult -eq "False"} | measure-object | select -expandproperty count) -gt 0){
    Write-Log "The following A records failed to ping:"
    $objs | where {$_.pingResult -eq "False"}
}