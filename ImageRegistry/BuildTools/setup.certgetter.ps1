param(
	$config
	,$domain
	)
Write-Log "Configureing the certgetter"
$out = NEw-Object PSObject -Property @{
	Domain = $domain
	Records = @()
}
foreach ($d in $config.Domains){
	$out.Records += $d.Records | Select hosts,name,uid,gid,signingProfile
}

$data = $out | ConvertTo-Json -depth 5 

set-content -Value $data -Path "$(Split-Path $PSScriptRoot -Parent)\mountPoints\certgetter\certrequests.json"