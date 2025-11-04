#!/bin/bash
set -euo pipefail

# ============================================================
# rotate_wg_keys_docker.sh
# Rotaciona chaves WireGuard entre dois nodes (Docker containers)
# Compatível com linuxserver/wireguard e WireGuard UI
# ============================================================

# CONFIGURAÇÕES ============================
WG_DIR="/gluster/shared_data/wg_config"
BACKUP_DIR="${WG_DIR}/backups"

REMOTE_NODE_IP="10.8.0.2"
REMOTE_USER="root"

# Containers WireGuard
LOCAL_CONTAINER="vpn-eu"
REMOTE_CONTAINER="vpn-eua"

# Arquivos de interface
IFACE_SERVERS_CONF="wg0.conf"              
IFACE_CLIENTS_CONF="wg0.clientes.conf"     

# Identificadores de peers (para atualizar PublicKey remoto)
LOCAL_10_8_IPV4="10.8.0.1/32"
LOCAL_10_9_IPV4="10.9.0.1/32"

# Tempo de espera entre reinícios (segundos)
SLEEP_AFTER_RESTART=5

# ============================================================
timestamp() { date +'%Y%m%d_%H%M%S'; }

mkdir -p "$BACKUP_DIR"

echo "[INFO] Iniciando rotação de chaves WireGuard em $(hostname)"
echo "[INFO] Backups serão salvos em: $BACKUP_DIR"

# ============================================================
# Gera novo par de chaves (priv/pub)
gen_keypair() {
    local priv pub
    priv=$(wg genkey)
    pub=$(printf '%s' "$priv" | wg pubkey)
    printf '%s\n%s' "$priv" "$pub"
}

# ============================================================
# Reinicia container Docker local ou remoto
restart_wg_container() {
    local container_name="$1"
    local node="$2"    # 'local' ou IP remoto
    local sleep_after="$3"

    echo "[INFO] Reiniciando container $container_name no node $node..."

    if [ "$node" == "local" ]; then
        docker restart "$container_name"
    else
        ssh -o StrictHostKeyChecking=accept-new "$node" "docker restart $container_name"
    fi

    echo "[INFO] Container $container_name reiniciado. Aguardando $sleep_after segundos..."
    sleep "$sleep_after"
}

# ============================================================
# Rotaciona interface e atualiza nó remoto
rotate_iface() {
    local local_file="$1"
    local local_allowed_for_remote="$2"
    local fullpath="${WG_DIR}/${local_file}"

    echo
    echo "=== Rotacionando chaves para ${local_file} ==="

    if [ ! -f "$fullpath" ]; then
        echo "[ERRO] Arquivo não encontrado: $fullpath — ignorando."
        return 0
    fi

    local ts
    ts=$(timestamp)

    # Backup local
    cp -a "$fullpath" "${BACKUP_DIR}/${local_file}.bak.${ts}"
    echo "[OK] Backup local criado: ${BACKUP_DIR}/${local_file}.bak.${ts}"

    # Gerar novo par
    read -r NEW_PRIV NEW_PUB < <(gen_keypair)
    echo "[INFO] Nova PublicKey: $NEW_PUB"

    # Substituir PrivateKey local
    awk -v np="$NEW_PRIV" '
    BEGIN{done=0}
    /^PrivateKey[[:space:]]*=/ && !done {print "PrivateKey = " np; done=1; next}
    {print}
    ' "$fullpath" > "${fullpath}.new"

    mv "${fullpath}.new" "$fullpath"
    chmod 600 "$fullpath"
    echo "[OK] PrivateKey atualizada localmente."

    # Atualizar remoto via SSH
    echo "[INFO] Atualizando PublicKey no nó remoto ($REMOTE_NODE_IP)..."

    ssh -o StrictHostKeyChecking=accept-new "${REMOTE_USER}@${REMOTE_NODE_IP}" bash -s -- "$local_allowed_for_remote" "$NEW_PUB" "$local_file" <<'REMOTE_SCRIPT'
set -euo pipefail
LOCAL_ALLOWED="$1"
NEW_PUB="$2"
CONF_NAME="$3"
WG_DIR="/shared_data/wg_config"
CONF_PATH="${WG_DIR}/${CONF_NAME}"
BACKUP_DIR="${WG_DIR}/backups"

mkdir -p "$BACKUP_DIR"
ts=$(date +'%Y%m%d_%H%M%S')

cp -a "$CONF_PATH" "${BACKUP_DIR}/$(basename "$CONF_PATH").bak.$ts"

awk -v allowed="$LOCAL_ALLOWED" -v newpub="$NEW_PUB" '
BEGIN{in_peer=0;found=0}
{
  if ($0 ~ /^\[Peer\]/) {in_peer=1;nextline=""}
  if (in_peer==1 && $0 ~ "AllowedIPs[[:space:]]*=[[:space:]]*"allowed) {found=1}
  if (found==1 && $0 ~ "^PublicKey[[:space:]]*=") {
    print "PublicKey = " newpub
    found=0;in_peer=0;next
  }
  print
}' "$CONF_PATH" > "${CONF_PATH}.new"

mv "${CONF_PATH}.new" "$CONF_PATH"
chmod 600 "$CONF_PATH"

echo "[REMOTE] PublicKey substituída com sucesso."
REMOTE_SCRIPT

}

# ============================================================
# EXECUÇÃO

# Rotaciona interfaces
rotate_iface "$IFACE_SERVERS_CONF" "$LOCAL_10_8_IPV4"
rotate_iface "$IFACE_CLIENTS_CONF" "$LOCAL_10_9_IPV4"

# Reinício seguro dos containers (primeiro remoto, depois local)
restart_wg_container "$REMOTE_CONTAINER" "$REMOTE_NODE_IP" $SLEEP_AFTER_RESTART
restart_wg_container "$LOCAL_CONTAINER" "local" $SLEEP_AFTER_RESTART

# Checagem rápida
echo "[INFO] Status local:"
docker exec "$LOCAL_CONTAINER" wg show

echo "[INFO] Status remoto:"
ssh "$REMOTE_USER@$REMOTE_NODE_IP" "docker exec $REMOTE_CONTAINER wg show"

echo
echo "[DONE] Rotação completa em $(hostname)."
echo "[INFO] Próxima rotação automática em 3 meses."
echo "[INFO] Logs salvos em ${BACKUP_DIR}/rotate_$(timestamp).log"
exit 0
