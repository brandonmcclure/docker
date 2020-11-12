[CmdletBinding(SupportsShouldProcess=$true)] 
param(
    $types = ('DW',""),
    [ValidateSet("2017","2019")]$year = '2019'

)
$baseURL = "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/"



[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
foreach($type in $types){
    if (-not (Test-Path "$($PSScriptRoot)\$($bakFileName)")){
        $bakFileName = "AdventureWorks$type$year.bak"
        $fullURL = "$($baseURL)$($bakFileName)"
        Write-Host "url: $fullURL"
        Invoke-WebRequest -Uri $fullURL -OutFile "$($PSScriptRoot)\$($bakFileName)"
    }
}