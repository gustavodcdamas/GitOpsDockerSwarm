#!/bin/bash
set -euo pipefail

# ============================================================
# generate_client_conf.sh (atualizado para watcher)
# Gera cliente WireGuard redundante (2 peers) com lock e logging
# ============================================================

WG_BASE_DIR="/gluster/shared_data/wg_config"
OUTPUT_DIR="${WG_BASE_DIR}/clientes"
LOG_FILE="/gluster/shared_data/logs/generate_client_conf.log"
LOCK_FILE="/gluster/shared_data/scripts/generate_client_conf.lock"

CLIENT_NAME="${1:-cliente-$(date +%Y%m%d%H%M%S)}"

# Containers WireGuard
SERVER1_CONTAINER="vpn-eu"
SERVER2_CONTAINER="vpn-eua"

# Configurações dos servidores
SERVER1_CONF="${WG_BASE_DIR}/eu/wg0.conf"
SERVER2_CONF="${WG_BASE_DIR}/eua/wg0.conf"

DNS_SERVERS="1.1.1.1, 1.0.0.1"
CLIENT_NET_BASE="10.9.0"
WG_INTERFACE="wg0"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# ============================================================
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# ============================================================
# Função para gerar par de chaves
gen_keypair() {
    local priv pub
    priv=$(wg genkey)
    pub=$(printf '%s' "$priv" | wg pubkey)
    printf '%s\n%s' "$priv" "$pub"
}

# ============================================================
# Obter informações dos servidores
get_server_info() {
    local conf="$1"
    local field="$2"
    grep -m1 -E "^${field}[[:space:]]*=" "$conf" | awk -F= '{print $2}' | tr -d ' '
}

get_server_pubkey() { get_server_info "$1" "PublicKey"; }
get_server_endpoint() { get_server_info "$1" "Endpoint"; }

SERVER1_PUB=$(get_server_pubkey "$SERVER1_CONF")
SERVER2_PUB=$(get_server_pubkey "$SERVER2_CONF")
SERVER1_EP=$(get_server_endpoint "$SERVER1_CONF")
SERVER2_EP=$(get_server_endpoint "$SERVER2_CONF")

if [[ -z "$SERVER1_PUB" || -z "$SERVER2_PUB" ]]; then
  log "[ERRO] Não foi possível obter as chaves públicas dos servidores."
  exit 1
fi

# ============================================================
# Lockfile para evitar concorrência
(
  flock -n 200 || { log "[WARN] Outro processo em execução. Saindo."; exit 0; }

  log "[INFO] Gerando cliente: $CLIENT_NAME"

  # Gerar chaves do cliente
  read -r CLIENT_PRIV CLIENT_PUB < <(gen_keypair)
  PRESHARED=$(wg genpsk)

  # Escolher IP disponível automaticamente
  NEXT_ID=$(($(ls "$OUTPUT_DIR" | grep -c '\.conf$') + 10))
  CLIENT_IP="${CLIENT_NET_BASE}.${NEXT_ID}/24"

  # ============================================================
  # Gerar configuração do cliente
  CLIENT_CONF_PATH="${OUTPUT_DIR}/${CLIENT_NAME}.conf"

  cat > "$CLIENT_CONF_PATH" <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIV}
Address = ${CLIENT_IP}
DNS = ${DNS_SERVERS}

[Peer]
# Servidor 1 (Europa)
PublicKey = ${SERVER1_PUB}
PresharedKey = ${PRESHARED}
Endpoint = ${SERVER1_EP}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25

[Peer]
# Servidor 2 (EUA)
PublicKey = ${SERVER2_PUB}
PresharedKey = ${PRESHARED}
Endpoint = ${SERVER2_EP}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

  chmod 600 "$CLIENT_CONF_PATH"
  log "[INFO] Arquivo cliente gerado: $CLIENT_CONF_PATH"

  # ============================================================
  # Adicionar cliente aos dois servidores
  for SERVER in "$SERVER1_CONTAINER" "$SERVER2_CONTAINER"; do
    log "[INFO] Adicionando peer $CLIENT_NAME ($CLIENT_IP) ao $SERVER..."
    docker exec "$SERVER" wg set "$WG_INTERFACE" peer "$CLIENT_PUB" preshared-key <(echo "$PRESHARED") allowed-ips "$CLIENT_IP" || {
      log "[ERRO] Falha ao adicionar peer no $SERVER"
    }

    # Persistir configuração permanentemente
    docker exec "$SERVER" bash -c "wg showconf $WG_INTERFACE > /config/wg0.conf && chmod 600 /config/wg0.conf"
  done

  # ============================================================
  # Status rápido
  log "[INFO] Status dos peers adicionados:"
  log "→ $SERVER1_CONTAINER:"
  docker exec "$SERVER1_CONTAINER" wg show | grep -A2 "$CLIENT_PUB" || true
  log "→ $SERVER2_CONTAINER:"
  docker exec "$SERVER2_CONTAINER" wg show | grep -A2 "$CLIENT_PUB" || true

  log "[✅] Cliente $CLIENT_NAME criado e configurado com sucesso."

) 200>"$LOCK_FILE"
