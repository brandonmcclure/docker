#https://codefresh.io/docker-tutorial/using-docker-generate-ssl-certificates/

# FROM nginx:1.19.1-alpine
# COPY san.cnf /san.cnf
# RUN apk update && \
#     apk add --no-cache openssl && \
#     openssl req -x509 -nodes -days 730 -newkey rsa:2048 \
#     -keyout /etc/ssl/private/nginx-selfsigned.key \
#     -out /etc/ssl/certs/nginx-selfsigned.crt \
#     -config /san.cnf && \
# 	 mkdir /work && \
# 	 cp /etc/ssl/certs/nginx-selfsigned.crt /work/nginx-selfsigned.crt && \
# 	 cp /etc/ssl/private/nginx-selfsigned.key /work/nginx-selfsigned.key
# RUN openssl x509 -in /etc/ssl/certs/nginx-selfsigned.crt -noout -text

FROM mcr.microsoft.com/powershell:lts-alpine-3.10

WORKDIR /work
COPY New-CFSSL_Certificate.ps1 /work/New-CFSSL_Certificate.ps1

ENTRYPOINT ["pwsh", "/work/New-CFSSL_Certificate.ps1"]