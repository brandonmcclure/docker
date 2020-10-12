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
&& echo "$AuthPassword" \
| htpasswd -niB $AuthUsername \
> /auth/htpasswd 
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \
   CMD curl --insecure --fail -u $AuthUsername:$AuthPassword https://localhost:$apiPort/v2/_catalog \
   && curl --insecure --fail http://localhost:$metricsPort/metrics || exit 1
