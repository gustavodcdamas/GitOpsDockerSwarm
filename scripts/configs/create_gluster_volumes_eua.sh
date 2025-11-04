#!/bin/bash
set -euo pipefail

# ==========================================
# Script para criar subpastas + volumes GlusterFS
# ==========================================

# Endereços dos nós Gluster
GLUSTER_IP_LOCAL="10.8.0.2"   # IP deste nó
GLUSTER_IP_PEER="10.8.0.1"    # IP do outro nó

SHARED_DIR="/gluster/shared_data"

# Lista de volumes (subpastas) das stacks anteriores + Mailu
VOLUMES=(
  psql_data
  nginx_etc
  nginx_ssl
  nginx_public
  vpn-admin-db
  wg_config
  wp-agencia-data
  redis_data
  rabbitmq_data
  rabbitmq_log
  perfex_data
  odoo-data
  odoo-lib
  odoo-extras
  n8n-data
  mysql-data
  minio-data
  agencia_uploads
  evolution-instances
  evolution-store
  easy_config
  docuseal_data
  chatwoot_app
  chatwoot_storage
  mail_data
  nextcloud_public
  nextcloud_data
  nextcloud_config
  # Mailu volumes
  mail
  mailqueue
  dovecot_overrides
  postfix_overrides
  filter
  dkim
  rspamd_overrides
  dav
  data
  webmail
  webmail_overrides
  # Volumes de Monitoramento
  grafana-storage-eua
  loki-data-eua
  alloy-data-eua
  prometheus-data-eua
  alertmanager-data-eua
)

echo "====================================="
echo "Criando subpastas em $SHARED_DIR..."
for vol in "${VOLUMES[@]}"; do
  if [ ! -d "$SHARED_DIR/$vol" ]; then
    mkdir -p "$SHARED_DIR/$vol"
    echo "Criada subpasta: $SHARED_DIR/$vol"
  else
    echo "Subpasta já existe: $SHARED_DIR/$vol"
  fi
done

echo "====================================="
echo "Criando volumes Docker GlusterFS..."
for vol in "${VOLUMES[@]}"; do
  if docker volume inspect "${vol}_gluster" >/dev/null 2>&1; then
    echo "Volume Docker já existe: ${vol}_gluster"
  else
    docker volume create \
      --driver local \
      --opt type=glusterfs \
      --opt device="$SHARED_DIR/$vol" \
      --opt o="addr=$GLUSTER_IP_LOCAL,backupvolfile-server=$GLUSTER_IP_PEER,_netdev" \
      "${vol}_gluster"
    echo "Volume Docker criado: ${vol}_gluster"
  fi
done

echo "====================================="
echo "Todos os volumes e subpastas foram verificados/criados com sucesso!"
