FROM nginx:1.19.3-alpine

# Install Powershell Core
RUN apk add --no-cache \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    curl \
    && apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust\
    && curl -LsS https://github.com/PowerShell/PowerShell/releases/download/v7.0.3/powershell-7.0.3-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz \
    && mkdir -p /opt/microsoft/powershell/7 \
    && tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

RUN apk add --no-cache \
    openssl \
    gettext

ARG basicAuthUsername
ARG basicAuthPassword
ENV AuthUsername=$basicAuthUsername
ENV AuthPassword=$basicAuthPassword

ARG ForwardPort=8888
ARG ForwardHost
ENV FORWARD_PORT=$ForwardPort \
    FORWARD_HOST=$ForwardHost

ARG httpPort=80
ARG httpsPort=443
ENV HTTP_PORT=$httpPort \
HTTPS_PORT=$httpsPort

RUN mkdir /auth \
&& printf "$AuthUsername:$(openssl passwd -crypt $AuthPassword)\n" >> /opt/auth.htpasswd  

WORKDIR /opt

COPY auth.conf launch.sh ./
COPY New-CFSSL_Certificate.ps1 /work/New-CFSSL_Certificate.ps1
#ENTRYPOINT tail -f /dev/null
CMD ["./launch.sh"]