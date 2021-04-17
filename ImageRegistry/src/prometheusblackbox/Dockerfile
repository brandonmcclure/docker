FROM prom/blackbox-exporter:master
COPY ca-bundle.crt /tmp/ca-bundle.crt

RUN cat /tmp/ca-bundle.crt >> /etc/ssl/certs/ca-certificates.crt
