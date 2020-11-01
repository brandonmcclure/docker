#!/bin/sh

pwsh /work/New-CFSSL_Certificate.ps1

rm /etc/nginx/conf.d/default.conf || :
envsubst < auth.conf > /etc/nginx/conf.d/auth.conf
envsubst < auth.htpasswd > /etc/nginx/auth.htpasswd

nginx -g "daemon off;"