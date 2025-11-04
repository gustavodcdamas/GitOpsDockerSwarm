#!/bin/bash
# Script para atualizar o .env do Chatwoot com IPs do Cloudflare

CLOUDFLARE_DIR="/opt/scripts/cloudflare"
CHATWOOT_ENV="/opt/scripts/reverse-proxy/public/zap/.env"  # AJUSTE PARA SEU CAMINHO
BACKUP_DIR="/opt/chatwoot/backups"

echo "$(date): Iniciando atualização do .env do Chatwoot" >> /var/log/chatwoot-env-update.log

# Criar backup
mkdir -p $BACKUP_DIR
cp $CHATWOOT_ENV "$BACKUP_DIR/.env.backup.$(date +%Y%m%d_%H%M%S)"

# Verificar se arquivo de IPs existe
if [ ! -f "$CLOUDFLARE_DIR/ips-env.txt" ]; then
    echo "$(date): ERRO: Arquivo ips-env.txt não encontrado!" >> /var/log/chatwoot-env-update.log
    exit 1
fi

# Extrair APENAS o valor da variável TRUSTED_PROXIES
TRUSTED_PROXIES_VALUE=$(grep "TRUSTED_PROXIES=" $CLOUDFLARE_DIR/ips-env.txt | cut -d'=' -f2)

if [ -z "$TRUSTED_PROXIES_VALUE" ]; then
    echo "$(date): ERRO: Não foi possível extrair TRUSTED_PROXIES" >> /var/log/chatwoot-env-update.log
    exit 1
fi

echo "$(date): Valor extraído: $TRUSTED_PROXIES_VALUE" >> /var/log/chatwoot-env-update.log

# Atualizar o .env do Chatwoot
if grep -q "TRUSTED_PROXIES=" $CHATWOOT_ENV; then
    # Se a variável já existe, substituir
    sed -i "s|TRUSTED_PROXIES=.*|TRUSTED_PROXIES=$TRUSTED_PROXIES_VALUE|" $CHATWOOT_ENV
    echo "$(date): Variável TRUSTED_PROXIES atualizada" >> /var/log/chatwoot-env-update.log
else
    # Se não existe, adicionar
    echo "TRUSTED_PROXIES=$TRUSTED_PROXIES_VALUE" >> $CHATWOOT_ENV
    echo "$(date): Variável TRUSTED_PROXIES adicionada" >> /var/log/chatwoot-env-update.log
fi

# Verificar se a atualização foi bem sucedida
if grep -q "TRUSTED_PROXIES=$TRUSTED_PROXIES_VALUE" $CHATWOOT_ENV; then
    echo "$(date): .env atualizado com SUCESSO" >> /var/log/chatwoot-env-update.log
else
    echo "$(date): ERRO: Falha ao atualizar .env" >> /var/log/chatwoot-env-update.log
    exit 1
fi

echo "$(date): Atualização do .env concluída" >> /var/log/chatwoot-env-update.log