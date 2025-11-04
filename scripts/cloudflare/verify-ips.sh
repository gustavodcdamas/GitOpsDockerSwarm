#!/bin/bash
# /opt/scripts/cloudflare/verify-ips.sh

CLOUDFLARE_DIR="/opt/scripts/cloudflare"
LOG_FILE="/var/log/cloudflare-verify.log"

echo "=== Verificação $(date) ===" >> $LOG_FILE

# Verificar se arquivos existem
echo "Verificando arquivos:" >> $LOG_FILE
ls -la $CLOUDFLARE_DIR/ >> $LOG_FILE

# Verificar IPs carregados
echo "IPs carregados no Nginx: $(grep -c "set_real_ip_from" $CLOUDFLARE_DIR/ips.conf)" >> $LOG_FILE
echo "IPs carregados no .env: $(wc -l $CLOUDFLARE_DIR/ips-env.txt)" >> $LOG_FILE

# Verificar serviços
echo "Status dos serviços:" >> $LOG_FILE
docker service ls | grep -E "(nextcloud|chatwoot|nginx)" >> $LOG_FILE

# Testar conectividade
echo "Teste de conectividade Cloudflare:" >> $LOG_FILE
curl -s https://www.cloudflare.com/ips-v4 | wc -l | xargs echo "IPs IPv4 disponíveis:" >> $LOG_FILE
curl -s https://www.cloudflare.com/ips-v6 | wc -l | xargs echo "IPs IPv6 disponíveis:" >> $LOG_FILE

echo "=== Fim da verificação ===" >> $LOG_FILE