param($config,$domain = '')


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
foreach($record in $config.Records){
	if(-not [bool]($record.PSobject.Properties.name -match "port")){
		continue;
	}
	if(-not [bool]($record.PSobject.Properties.name -match "upstreamScheme")){
		$upstreamScheme = "http"
	}
	else{
		$upstreamScheme = "https"
	}

	if(-not [bool]($record.PSobject.Properties.name -match "Authentication")){
		$outConfig += "
server {
	listen      80;
	listen [::]:80;
	server_name $($record.Name).$domain;

	# this is the internal Docker DNS, cache only for 30s
	resolver 127.0.0.11 valid=30s;
	return 301 https://`$host`$request_uri;
}
server {
	ssl_certificate /etc/nginx/conf.d/$($record.Name)/cert.crt;
	 ssl_certificate_key /etc/nginx/conf.d/$($record.Name)/cert.key;
	ssl_session_timeout  5m;
	ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers          ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+EXP;
	ssl_prefer_server_ciphers   on;
	listen      443 ssl;
	listen [::]:443 ssl;
	server_name $($record.Name).$domain;

	# this is the internal Docker DNS, cache only for 30s
	resolver 127.0.0.11 valid=30s;
	location / {


		proxy_set_header Host `$host;
		proxy_set_header X-Real-IP `$remote_addr;
		proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto `$scheme;
		 set `$upstream $($upstreamScheme)://$($record.Name):$($record.port);
		 proxy_pass `$upstream;

		 proxy_redirect $($upstreamScheme)://$($record.Name):$($record.port) https://$($record.Name).$domain;
	}
}"
	}
	else{
		$outConfig += "
server {
	listen      80;
	listen [::]:80;
	server_name $($record.Name).$domain;

	# this is the internal Docker DNS, cache only for 30s
	resolver 127.0.0.11 valid=30s;
	return 301 https://`$host`$request_uri;
}
server {
	auth_basic           `"Administrator's Area`";
	auth_basic_user_file /etc/nginx/basicAuth/.htpasswd;
	ssl_certificate /etc/nginx/conf.d/$($record.Name)/cert.crt;
	 ssl_certificate_key /etc/nginx/conf.d/$($record.Name)/cert.key;
	ssl_session_timeout  5m;
	ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers          ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+EXP;
	ssl_prefer_server_ciphers   on;
	listen      443 ssl;
	listen [::]:443 ssl;
	server_name $($record.Name).$domain;

	# this is the internal Docker DNS, cache only for 30s
	resolver 127.0.0.11 valid=30s;
	location / {


		proxy_set_header Host `$host;
		proxy_set_header X-Real-IP `$remote_addr;
		proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto `$scheme;
		 set `$upstream $($upstreamScheme)://$($record.Name):$($record.port);
		 proxy_pass `$upstream;

		 proxy_redirect $($upstreamScheme)://$($record.Name):$($record.port) https://$($record.Name).$domain;
	}
}"
	}

}
$outConfig += "}"
Write-Output $outConfig