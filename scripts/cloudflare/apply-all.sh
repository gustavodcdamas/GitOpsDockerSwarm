#!/bin/bash
# /opt/scripts/cloudflare/apply-all.sh

LOG_FILE="/var/log/cloudflare-apply.log"
CLOUDFLARE_DIR="/opt/scripts/cloudflare"

echo "$(date): Iniciando aplicação das configurações Cloudflare" >> $LOG_FILE

# 1. Atualizar Nextcloud
echo "$(date): Atualizando Nextcloud..." >> $LOG_FILE
docker service update --force nextcloud_app >> $LOG_FILE 2>&1

# 2. Atualizar Chatwoot (CRÍTICO)
echo "$(date): Atualizando Chatwoot..." >> $LOG_FILE

# Primeiro atualizar o .env do Chatwoot
if [ -f "$CLOUDFLARE_DIR/ips-env.txt" ]; then
    # Carregar a variável TRUSTED_PROXIES do arquivo
    source $CLOUDFLARE_DIR/ips-env.txt
    
    # Atualizar o .env do Chatwoot
    CHATWOOT_ENV_PATH="/opt/chatwoot/.env"  # Ajuste conforme seu setup
    
    if [ -f "$CHATWOOT_ENV_PATH" ]; then
        # Backup do arquivo original
        cp $CHATWOOT_ENV_PATH "${CHATWOOT_ENV_PATH}.backup.$(date +%Y%m%d)"
        
        # Atualizar ou adicionar TRUSTED_PROXIES
        if grep -q "TRUSTED_PROXIES=" $CHATWOOT_ENV_PATH; then
            sed -i "s|TRUSTED_PROXIES=.*|TRUSTED_PROXIES=$TRUSTED_PROXIES|" $CHATWOOT_ENV_PATH
        else
            echo "TRUSTED_PROXIES=$TRUSTED_PROXIES" >> $CHATWOOT_ENV_PATH
        fi
        
        echo "$(date): .env do Chatwoot atualizado" >> $LOG_FILE
    fi
fi

# Recarregar serviço Chatwoot
docker service update --force cuei-zap >> $LOG_FILE 2>&1

# 3. Recarregar Nginx
echo "$(date): Recarregando Nginx..." >> $LOG_FILE
nginx -t && nginx -s reload >> $LOG_FILE 2>&1

# 4. Outros serviços (ajuste conforme necessário)
echo "$(date): Atualizando outros serviços..." >> $LOG_FILE
docker service update --force nginx >> $LOG_FILE 2>&1
# docker service update --force odoo_app >> $LOG_FILE 2>&1
# docker service update --force wordpress_app >> $LOG_FILE 2>&1

echo "$(date): Todas as configurações foram aplicadas com sucesso" >> $LOG_FILE