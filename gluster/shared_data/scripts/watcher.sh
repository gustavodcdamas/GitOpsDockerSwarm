#!/bin/bash
set -euo pipefail

WATCH_DIR="/gluster/shared_data/clientes"
SCRIPT_CLIENT_CONF="/gluster/shared_data/scripts/generate_client_conf.sh"
LOCK_FILE="/gluster/shared_data/scripts/watcher.lock"

mkdir -p "$WATCH_DIR"
mkdir -p "/gluster/shared_data/logs"

echo "[INFO] Watcher iniciado em $(date)" >> /gluster/shared_data/logs/watcher.log

inotifywait -m -e create --format "%f" "$WATCH_DIR" | while read NEW_FILE; do
  echo "[INFO] Novo arquivo detectado: $NEW_FILE" >> /gluster/shared_data/logs/watcher.log

  # Usar lockfile para evitar execuções concorrentes
  (
    flock -n 200 || { echo "[WARN] Outro processo ainda rodando, pulando..."; exit 0; }
    echo "[INFO] Executando script generate_client_conf.sh para $NEW_FILE" >> /gluster/shared_data/logs/watcher.log
    bash "$SCRIPT_CLIENT_CONF" "$NEW_FILE"
  ) 200>"$LOCK_FILE"
done
