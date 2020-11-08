param(
	$certRequests = @(
		[PSCustomObject]@{name = 'registry'; hosts = @('ImageRegistry','localhost','127.0.0.1')}
		,[PSCustomObject]@{name = 'grafana'; hosts = @('grafana','localhost','127.0.0.1')}
		,[PSCustomObject]@{name = 'squidwebui'; hosts = @('squidwebui','localhost','127.0.0.1','proxy.example.com')}
	),
	$Country = "US",
	$State = "Colorado",
	$Location = "Denver",
	$caURL = 'http://ca:8888',
	$ca_basicaauth_Username = '',
	$ca_basicaauth_Password = '',
    $certOutPath = '/mnt'
)
Write-Host "certRequests"
Get-Member -InputObject $certRequests
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
			"CN": "'+$request.name+'"
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
}
tail -f /dev/null