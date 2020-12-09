FROM registry:2.7.0
RUN apk update --no-cache && apk add --no-cache curl
ARG basicAuthUsername
ARG basicAuthPassword
ARG apiPort
ARG metricsPort
COPY config.yml /etc/docker/registry/config.yml
ENV AuthUsername=$basicAuthUsername
ENV AuthPassword=$basicAuthPassword
ENV apiPort=$apiPort
ENV metricsPort=$metricsPort
RUN mkdir /auth \
&& if [ ! -z "${AuthUsername}" ]; then \
 echo "$AuthPassword" \
| htpasswd -niB $AuthUsername \
> /auth/htpasswd; fi
# After https://github.com/docker/distribution/issues/3189 is resolved, upgrade to 2.7.1 of the image, which should bump up alpine 3.9 via this pr:https://github.com/docker/distribution/pull/2946?_pjax=%23js-repo-pjax-container
# Then install PS on this container
# RUN cat /etc/os-release
# RUN apk add --no-cache \
#     ca-certificates \
#     less \
#     ncurses-terminfo-base \
#     krb5-libs \
#     libgcc \
#     libintl \
#     libssl1.1 \
#     libstdc++ \
#     tzdata \
#     userspace-rcu \
#     zlib \
#     icu-libs \
#     curl \
#     && apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
#     lttng-ust\
#     && curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.0.3/powershell-7.0.3-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz \
#     && mkdir -p /opt/microsoft/powershell/7 \
#     && tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
#     && chmod +x /opt/microsoft/powershell/7/pwsh \
#     && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

HEALTHCHECK --interval=60s --timeout=3s --start-period=10s --retries=5 \
   CMD curl --insecure --fail -u $AuthUsername:$AuthPassword https://localhost:$apiPort/v2/_catalog \
   && curl --insecure --fail http://localhost:$metricsPort/metrics || exit 1
