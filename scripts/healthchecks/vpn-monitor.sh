#!/bin/bash
# /opt/scripts/vpn-monitor.sh

LOG_FILE="/var/log/vpn-monitor.log"
ALERT_EMAIL="seu-email@dominio.com"  # Opcional

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

check_vpn_status() {
    local container_id=$1
    local peer_public_key=$2
    local server_name=$3
    
    echo "=== Verificando $server_name ==="
    
    # Verifica se o container está rodando
    if ! docker ps | grep -q $container_id; then
        echo -e "${RED}❌ Container não está rodando${NC}"
        log "ERRO: Container $server_name não está rodando"
        return 1
    fi
    
    # Verifica status do WireGuard
    local wg_status=$(docker exec $container_id wg show 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erro ao executar wg show${NC}"
        log "ERRO: Não foi possível verificar status do WireGuard em $server_name"
        return 1
    fi
    
    # Verifica handshake recente (últimos 2 minutos)
    local handshake_time=$(echo "$wg_status" | grep "latest handshake" | awk '{print $5}')
    local handshake_unit=$(echo "$wg_status" | grep "latest handshake" | awk '{print $6}')
    
    if [[ "$handshake_unit" == "minutes" && "$handshake_time" -gt 2 ]] || [[ "$handshake_unit" == "hours" ]]; then
        echo -e "${YELLOW}⚠️  Handshake antigo: $handshake_time $handshake_unit${NC}"
        log "ALERTA: Handshake antigo em $server_name - $handshake_time $handshake_unit"
    else
        echo -e "${GREEN}✅ Handshake recente: $handshake_time $handshake_unit${NC}"
    fi
    
    # Verifica transferência de dados
    local transfer=$(echo "$wg_status" | grep "transfer" | head -1)
    echo "📊 Transferência: $transfer"
    
    # Teste de ping
    if [[ $server_name == "SERVER1" ]]; then
        local target_ip="10.2.0.1"
    else
        local target_ip="10.1.0.1"
    fi
    
    if docker exec $container_id ping -c 3 -W 2 $target_ip &>/dev/null; then
        echo -e "${GREEN}✅ Ping bem-sucedido para $target_ip${NC}"
    else
        echo -e "${RED}❌ Falha no ping para $target_ip${NC}"
        log "ERRO: Falha no ping de $server_name para $target_ip"
    fi
    
    echo ""
}

# Monitoramento principal
echo "Iniciando monitoramento VPN..."
log "Iniciando monitoramento VPN"

# Servidor 1
check_vpn_status "86c887bc690f" "TXxPPClL0YZPGdzOcxYOqz6cMDjX217Pqf/jZHIQ8iE=" "SERVER1"

# Servidor 2  
check_vpn_status "271b8cdd81f7" "KNMU2C6QiC07I56XmPsv+KxG3JhXcliL/CEfYW53uzk=" "SERVER2"

echo "Monitoramento concluído. Log: $LOG_FILE"