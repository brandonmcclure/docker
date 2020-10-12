FROM quiq/docker-registry-ui
COPY config.yml /opt/config.yml
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \
   CMD wget -no-verbose --tries=1 --spider http://localhost:8000 || exit 1