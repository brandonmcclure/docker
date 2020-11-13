param(
	$dev_bindings = $true,
	$certRequests = @(
		[PSCustomObject]@{name = 'registry'; hosts = @('ImageRegistry')}
		,[PSCustomObject]@{name = 'grafana'; hosts = @('registry','proxy')}
		,[PSCustomObject]@{name = 'squid'; hosts = @('proxy'); uid = '200'; gid = '200'}
		,[PSCustomObject]@{name = 'registryui_reverseproxy'; hosts = @('ImageRegistry','registry');}
		,[PSCustomObject]@{name = 'ca_reverseproxy'; hosts = @('ca');}
	),
	$Country = "US",
	$State = "Colorado",
	$Location = "Denver",
	$caURL = 'http://ca:8888',
	$ca_basicaauth_Username = '',
	$ca_basicaauth_Password = '',
	$certOutPath = '/mnt',
	$domainName = '.mcd.com' # Will be suffixed onto each host
)
$newRequests =@()
foreach($certRequestIndex in 0..$(($certRequests | measure-object | select -ExpandProperty Count)-1)){
	$newRequest = $certRequests[$certRequestIndex]
	$hosts = @()
	$hosts += $newRequest.name
	if(	 -not [string]::IsNullOrEmpty($domainName)){
		$hosts +="$($newRequest.name)$domainName"
	}
	foreach($certRequestIndex_HostIndex in 0..$(($newRequest.hosts | measure-object | select -ExpandProperty Count)-1)){
		if(	 -not [string]::IsNullOrEmpty($domainName)){
			$hosts +="$($($certRequests[$certRequestIndex].hosts[$certRequestIndex_HostIndex]))$domainName"
		}
		$hosts += "$($certRequests[$certRequestIndex].hosts[$certRequestIndex_HostIndex])"

	}
	if($dev_bindings){
		$hosts += @('localhost','127.0.0.1')
	}

	$newRequest.hosts = $hosts
	$newRequests += $newRequest
}
Write-Host "certRequests"
$certRequests = $newRequests
$certRequests | fl
$authOptions = @{}
if (-not [string]::IsNullOrEmpty($ca_basicaauth_Username)){
	Write-Host "Makeing basic auth credentials"
	$secStringPassword = ConvertTo-SecureString $ca_basicaauth_Password -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential ($ca_basicaauth_Username, $secStringPassword)
	$authOptions = @{
		Credential = $cred
		}
}

if([string]::IsNullOrEmpty($caURL)){
	Write-Error "Please pass a caURL to use." -ErrorAction Stop
}
Write-Host "Useing the ca url: $caURL"
Write-Host "Creating certificates for $($certRequests | Measure-Object | Select-Object -ExpandProperty Count) requests"
foreach ($request in $certRequests){
	if (-not [bool]($request.PSobject.Properties.name -match "name") -or -not [bool]($request.PSobject.Properties.name -match "hosts")){
		Write-Host $request
		Write-Error "request def does not have a name or hosts property. Try again" -ErrorAction Stop
	}
	$request 
	$result = $null
	$body = '{
		"request": {
			"hosts": ["' + $($request.hosts -join '","') +'"],
			"names": [
				{
					"C": "'+$Country+'",
					"ST": "'+$State+'",
					"L": "'+$Location+'"
				}
			],
			"CN": "'+$(if(	 -not [string]::IsNullOrEmpty($domainName)){
				$hosts +="$($request.name)$domainName"
			}else{$request.name})+'"
		}
	}'

	Write-Verbose "newcert request body: $body"
	$result = Invoke-RestMethod -Method Post -Uri $caURL/api/v1/cfssl/newcert -Body $body -ContentType Application/JSON @authOptions

	if([string]::IsNullOrEmpty($result)){
		Write-Error "Did not get a response from server" -ErrorAction Stop
	}

	if ($result.success -ne "True"){
		Write-Error "response completed, but CFSSL reports failure" -ErrorAction Stop
	}

	Write-Host "Getting cert request from response"
	$cert = $result.result | select-object certificate_request


	Write-Host "Creating cert.key file from response"
	$result.result.private_key | Out-File cert.key

	$body = $($cert | ConvertTo-Json)
	#$body = $($body | ConvertFrom-Json) | select *,@{Name="Bundle";Expression={$true}} | ConvertTo-Json # Not sure if there is a need to bundle, I get an error when I do
	Write-Verbose "sign request body: $body"
	$result = $null
	$result = Invoke-RestMethod -Method Post -Uri $caURL/api/v1/cfssl/sign -Body $body -ContentType Application/JSON @authOptions
	$result | fl 
	Write-Host "Creating cert.crt file from signing response"
	$result.result.certificate | Out-File cert.crt

	Get-ChildItem /work
	Copy-Item -Path /work/cert.crt -Destination $certOutPath/$($request.name)_certs/cert.crt
	Copy-Item -Path /work/cert.key -Destination $certOutPath/$($request.name)_certs/cert.key 

	if (-not [string]::IsNullOrEmpty($request.uid) -and -not [string]::IsNullOrEmpty($request.gid)){
		Write-Host "Setting the UID:GID ownership"
		chown $($request.uid):$($request.gid) $certOutPath/$($request.name)_certs/cert.crt
		chown $($request.uid):$($request.gid) $certOutPath/$($request.name)_certs/cert.key
	}
}
tail -f /dev/null