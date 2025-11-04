#!/bin/bash
# /opt/cloudflare-healthcheck.sh

HEALTH_CHECK_PORT=8080

# Verificar se Docker está rodando
if ! systemctl is-active --quiet docker; then
    exit 1
fi

# Verificar se containers críticos estão saudáveis
CRITICAL_CONTAINERS=("nginx" "database" "app")
for container in "${CRITICAL_CONTAINERS[@]}"; do
    if ! docker ps --filter "name=$container" --format "{{.Status}}" | grep -q "Up"; then
        echo "Container $container não está rodando"
        exit 1
    fi
done

# Verificar uso de recursos (opcional)
LOAD_AVG=$(cat /proc/loadavg | awk '{print $1}')
if (( $(echo "$LOAD_AVG > 4.0" | bc -l) )); then
    echo "Load average muito alto: $LOAD_AVG"
    exit 1
fi

# Verificar espaço em disco
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo "Uso de disco muito alto: $DISK_USAGE%"
    exit 1
fi

exit 0