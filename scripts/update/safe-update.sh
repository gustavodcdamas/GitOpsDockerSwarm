#!/bin/bash

LOG_FILE="/var/log/system-updates.log"
EMAIL="monitoramento@gustavodcdamas.com.br"

echo "$(date) - Iniciando atualização segura" >> $LOG_FILE

# 1. Backup rápido dos containers críticos
docker commit nginx nginx-backup-$(date +%Y%m%d)
docker commit database database-backup-$(date +%Y%m%d)

# 2. Atualizar lista de pacotes
apt-get update

# 3. Atualizar APENAS pacotes de segurança
apt-get upgrade --only-upgrade-security -y

# 4. Atualizar Docker containers (se necessário)
docker-compose pull
docker-compose up -d

# 5. Verificar se serviços estão rodando
if systemctl is-active --quiet docker && docker ps | grep -q "Up"; then
    echo "$(date) - Atualização concluída com sucesso" >> $LOG_FILE
    # Limpar backups antigos (manter últimos 7 dias)
    find /var/lib/docker/backups -name "*-backup-*" -mtime +7 -delete
else
    echo "$(date) - ERRO: Serviços não iniciados após atualização" >> $LOG_FILE
    # Restaurar backup
    docker run --rm -v /var/lib/docker/backups:/backup alpine \
        cp /backup/ultimo-backup.tar.gz /restore/
    exit 1
fi