param($config,$domain = '',[switch] $DisableIngressStub,[int] $dnsTimeout = 5)


function CreateHtpasswd{
	param($serviceName, $htpasswordPath)
	$creds = Get-Credential -Message "Enter the credentials for the $($serviceName) basic auth"
		(docker run --rm -it -v ${PWD}:/work bmcclure89/docker-htpassword $($creds.Username) $($creds.GetNetworkCredential().Password)) | Add-Content "$htpasswordPath"
}
$outConfig = "events {
    use           epoll;
    worker_connections  128;
}
http {
	server_tokens off;
	add_header X-Frame-Options SAMEORIGIN;
	add_header X-Content-Type-Options nosniff;
	add_header X-XSS-Protection `"1; mode=block`";
"
if(-not $DisableIngressStub){
	$outConfig += "server {
		listen      80;
		listen [::]:80;
		server_name ingress;
	
		location /stub_status {
		  # copied from http://blog.kovyrin.net/2006/04/29/monitoring-nginx-with-rrdtool/
	  stub_status   on;
		  access_log    off;
	
	  allow all;
	  deny all;
	}
	}"
}

foreach($record in $config.Records){
	if(-not [bool]($record.PSobject.Properties.name -match "port")){
		continue;
	}

	$SnippetHttpToHttpsRedirect = "server {
		listen      80;
		listen [::]:80;
		server_name $($record.Name).$domain;
	
		# this is the internal Docker DNS, cache only for $($dnsTimeout)s
		resolver 127.0.0.11 valid=$($dnsTimeout)s;
		return 301 https://`$host`$request_uri;
	}
	"
	$locations = @()
	$upstreamScheme = "http"
	if([bool]($record.PSobject.Properties.name -match "upstreamScheme")){
		$upstreamScheme = $record.upstreamScheme
	}
	$upstreamService = $record.Name
	if([bool]($record.PSobject.Properties.name -match "upstreamService")){
		$upstreamService = $record.upstreamService
	}

	$locations += "location / {
		proxy_set_header Host `$host;
		proxy_set_header X-Real-IP `$remote_addr;
		proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto `$scheme;
		 set `$upstream $($upstreamScheme)://$($upstreamService):$($record.port);
		 proxy_pass `$upstream;

		 proxy_redirect $($upstreamScheme)://$($upstreamService):$($record.port) https://$($record.Name).$domain;
	}"

	if( [bool]($record.PSobject.Properties.name -match "ingressMappings")){
		foreach ($mp in $record.ingressMappings){
			$locations += "location $($mp.endpoint) {
					proxy_set_header Host `$host;
					proxy_set_header X-Real-IP `$remote_addr;
					proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
					proxy_set_header X-Forwarded-Proto `$scheme;
					 set `$upstream $($upstreamScheme)://$($mp.ToService):$($mp.port);
					 proxy_pass `$upstream;
			
					 proxy_redirect $($upstreamScheme)://$($mp.ToService):$($mp.port) https://$($record.Name).$domain;
				}
			"
		}
	}
	if(-not [bool]($record.PSobject.Properties.name -match "Authentication")){
		
		
		$outConfig += "
$SnippetHttpToHttpsRedirect
server {
	ssl_certificate /etc/nginx/conf.d/certs/$($record.Name)/cert.crt;
	 ssl_certificate_key /etc/nginx/conf.d/certs/$($record.Name)/cert.key;
	ssl_session_timeout  5m;
	ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers          ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+EXP;
	ssl_prefer_server_ciphers   on;
	listen      443 ssl;
	listen [::]:443 ssl;
	server_name $($record.Name).$domain;

	# this is the internal Docker DNS, cache only for $($dnsTimeout)s
	resolver 127.0.0.11 valid=$($dnsTimeout)s;
	$($locations -join '
	')
}"
	}
	else{
		$basicAuthPath = "$(Split-Path $PSScriptRoot -Parent)/mountPoints/ingress/basicAuth"
		$htpasswordPath = "$basicAuthPath/$($record.Name).htpasswd"
		$setupHTPasswd = $true
		if(Test-Path $htpasswordPath){
			$userResponse = Read-Host -Prompt "A htpasswd file alread exists for $($record.Name). Do you want to overwrite? (Type Yes to confirm"
			if($userResponse -ne "Yes"){
				Write-Log "Keeping the existing htpasswd file"
				$setupHTPasswd = $false;
			}
			else{
				Remove-Item $htpasswordPath
			}
		}

		if($setupHTPasswd){
			CreateHtpasswd -htpasswordPath $htpasswordPath -serviceName $record.Name
			$userResponse = Read-Host -Prompt "Do you want to add another user for this service? (Yes/No)"
			while($userResponse -eq "Yes"){
				
			CreateHtpasswd -htpasswordPath $htpasswordPath -serviceName $record.Name
				$userResponse = Read-Host -Prompt "Do you want to add another user for this service? (Yes/No)"
			}
		}

		$outConfig += "
$SnippetHttpToHttpsRedirect
server {
	auth_basic           `"Administrator's Area`";
	auth_basic_user_file /etc/nginx/basicAuth/$($record.Name).htpasswd;
	ssl_certificate /etc/nginx/conf.d/certs/$($record.Name)/cert.crt;
	 ssl_certificate_key /etc/nginx/conf.d/certs/$($record.Name)/cert.key;
	ssl_session_timeout  5m;
	ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers          ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+EXP;
	ssl_prefer_server_ciphers   on;
	listen      443 ssl;
	listen [::]:443 ssl;
	server_name $($record.Name).$domain;

	# this is the internal Docker DNS, cache only for $($dnsTimeout)s
	resolver 127.0.0.11 valid=$($dnsTimeout)s;
	$($locations -join '\r\n')
}"
	}

}
$outConfig += "}"
Write-Output $outConfig