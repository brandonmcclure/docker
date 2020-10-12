FROM prom/prometheus
COPY prometheus.yml /etc/prometheus/prometheus.yml

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \ 
    CMD wget --spider http://localhost:9090 || exit 1