#!/bin/bash
CLOUDFLARE_DIR="/opt/scripts/cloudflare"
LOG_FILE="/var/log/cloudflare-ips-update.log"

echo "$(date): Iniciando atualização dos IPs do Cloudflare" >> $LOG_FILE

mkdir -p $CLOUDFLARE_DIR

# Baixar IPs atuais
IPV4_URL="https://www.cloudflare.com/ips-v4"
IPV6_URL="https://www.cloudflare.com/ips-v6"

# ... (código para baixar IPs igual antes) ...

# ✅ FORMATO .env CORRETO - criar arquivo COM a variável
echo "# Cloudflare IP ranges - Auto-generated $(date)" > $CLOUDFLARE_DIR/ips-env.txt
echo -n "TRUSTED_PROXIES=" >> $CLOUDFLARE_DIR/ips-env.txt
curl -s $IPV4_URL | tr '\n' ',' >> $CLOUDFLARE_DIR/ips-env.txt
curl -s $IPV6_URL | tr '\n' ',' >> $CLOUDFLARE_DIR/ips-env.txt
# Remove última vírgula
sed -i 's/,$//' $CLOUDFLARE_DIR/ips-env.txt

echo "$(date): IPs atualizados com sucesso" >> $LOG_FILE

# ✅ AGORA ATUALIZAR O .env DO CHATWOOT
/opt/scripts/cloudflare/update-chatwoot-env.sh

# ✅ APLICAR NAS OUTRAS APLICAÇÕES
/opt/scripts/cloudflare/apply-all.sh

echo "$(date): Processo completo concluído" >> $LOG_FILE