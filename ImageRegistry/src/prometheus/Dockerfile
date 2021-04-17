FROM prom/prometheus:v2.26.0
USER root
COPY ca-bundle.crt /tmp/ca-bundle.crt

RUN cat /tmp/ca-bundle.crt >> /etc/ssl/certs/ca-certificates.crt

USER nobody