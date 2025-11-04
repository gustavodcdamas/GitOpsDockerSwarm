#!/bin/sh

GLUSTER_PATH="/gluster/shared_data"
READY_FILE="${GLUSTER_PATH}/.gluster_ready"
TIMEOUT=120  # segundos
SLEEP_INTERVAL=3

echo "[Sentinela] Aguardando montagem GlusterFS em ${GLUSTER_PATH}..."

elapsed=0
while [ $elapsed -lt $TIMEOUT ]; do
  if mountpoint -q "${GLUSTER_PATH}" && [ -d "${GLUSTER_PATH}" ]; then
    echo "[Sentinela] Montagem detectada, verificando escrita..."
    echo "ok" > "${READY_FILE}" 2>/dev/null
    if [ -f "${READY_FILE}" ]; then
      echo "[Sentinela] GlusterFS pronto. Arquivo .gluster_ready criado."
      exit 0
    fi
  fi
  sleep $SLEEP_INTERVAL
  elapsed=$((elapsed + SLEEP_INTERVAL))
done

echo "[ERRO] Timeout: GlusterFS não montou em ${TIMEOUT}s."
exit 1
