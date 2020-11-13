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

WORKDIR /opt

COPY auth.conf launch.sh ./

# If we build the iamge with a AuthUsername argument/env variable then create the htpasswd file and update the auth.conf file to let nginx know to use basic auth
RUN mkdir /auth \
&& if [ ! -z "${AuthUsername}" ]; then printf "$AuthUsername:$(openssl passwd -crypt $AuthPassword)\n" >> /opt/auth.htpasswd; sed -i $'s/location \/ {/location \/ {\\\n auth_basic\\n"Restricted"; \\\nauth_basic_user_file    auth.htpasswd;/' /opt/auth.conf; fi



#ENTRYPOINT tail -f /dev/null
CMD ["./launch.sh"]