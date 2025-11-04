#!/bin/bash

# Configurações gerais
SOURCE_DIRS=("/var/reverse-proxy" "/var/lib/docker/volumes") # Diretórios de origem
BACKUP_DIR="/backup"  # Diretório de destino dos backups
LOG_FILE="/var/reverse-proxy/logs/backup_incremental.log"  # Log do backup
BACKUP_DATE=$(date +'%Y-%m-%d')  # Data atual
DAILY_BACKUP="$BACKUP_DIR/daily/$BACKUP_DATE"  # Backup diário
LATEST_BACKUP="$BACKUP_DIR/latest"  # Diretório do último backup

# Configuração do Rclone
RCLONE_REMOTE="google_drive:Backups"  # Caminho remoto do Google Drive

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_telegram() {
    local MESSAGE="$1"
    local TELEGRAM_BOT_TOKEN="8030044150:AAEf4QbGw8NuSPsX8KpOJ8B53IqTqd160PE"
    local CHAT_ID="-1002211772665"  # ID do canal/grupo
    local THREAD_ID="1747"  # Substitua pelo ID da thread específica

    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d message_thread_id="$THREAD_ID" \
        -d text="$MESSAGE"
}

send_email() {
    local to_addr="$1"       # Primary recipient(s)
    local cc_addr="$2"       # CC recipient(s)
    local subject="$3"       # Email subject
    local body="$4"          # Email body (can be a file or a string)
    local attach="$5"        # Attachment file (optional)

    # Check if the body is a file or a string
    if [[ -f "$body" ]]; then
        body_content=$(cat "$body")
    else
        body_content="$body"
    fi

    # Send the email
    if [[ -n "$attach" && -f "$attach" ]]; then
        echo "$body_content" | mutt -s "$subject" -c "$cc_addr" -a "$attach" -- "$to_addr"
    else
        echo "$body_content" | mutt -s "$subject" -c "$cc_addr" -- "$to_addr"
    fi

    # Check if the email was sent successfully
    if [[ $? -eq 0 ]]; then
        echo "Email sent successfully to $to_addr"
    else
        echo "Error: Failed to send email to $to_addr"
        return 1
    fi
}

# Criar diretórios necessários
mkdir -p "$DAILY_BACKUP"
mkdir -p "$LATEST_BACKUP"

log "Iniciando backup incremental..."
send_email "gustavodcdamas@gmail.com" "kadegiovani@gmail.com" "Backup Iniciado" "Backup Iniciado às $(date +'%Y-%m-%d %H:%M:%S')." "/var/reverse-proxy/logs/backup_incremental.log"
send_telegram "🛠️ Iniciando backup incremental..."

# Parando nginx
log "Parando nginx..."
docker-compose -f /var/reverse-proxy/docker-compose.yml down
if [ $? -ne 0 ]; then
    log "Erro ao parar nginx."
    send_telegram "❌ Erro ao parar o container nginx!"
    send_email "Erro no Backup" "Erro ao parar o container nginx às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Nginx parados."

log "Parando calcom..."
docker-compose -f /var/reverse-proxy/public/agenda/docker/docker-compose.yaml down
if [ $? -ne 0 ]; then
    log "Erro ao parar container calcom."
    send_telegram "❌ Erro ao parar o container calcom!"
    send_email "Erro no Backup" "Erro ao parar o container calcom às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container calcom parado com sucesso."

log "Parando drive..."
docker-compose -f /var/reverse-proxy/public/drive/docker-compose.yml down
if [ $? -ne 0 ]; then
    log "Erro ao parar container drive."
    send_telegram "❌ Erro ao parar o container drive!"
    send_email "Erro no Backup" "Erro ao parar o container drive às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container drive parado com sucesso."

log "Parando evolution..."
docker-compose -f /var/reverse-proxy/public/evo/docker-compose.yml down
if [ $? -ne 0 ]; then
    log "Erro ao parar container evolution."
    send_telegram "❌ Erro ao parar o container evolution!"
    send_email "Erro no Backup" "Erro ao parar o container evolution às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container evolution parado com sucesso."

log "Parando N8N..."
docker-compose -f /var/reverse-proxy/public/n8nfila/docker-compose.yml down
if [ $? -ne 0 ]; then
    log "Erro ao parar N8N."
    send_telegram "❌ Erro ao parar o container N8N!"
    send_email "Erro no Backup" "Erro ao parar o container N8N às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container N8N parado com sucesso."

log "Parando Odoo..."
docker-compose -f /var/reverse-proxy/public/odoo/docker-compose.yml down
if [ $? -ne 0 ]; then
    log "Erro ao parar container Odoo."
    send_telegram "❌ Erro ao parar o container Odoo!"
    send_email "Erro no Backup" "Erro ao parar o container Odoo às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container odoo parado com sucesso."

log "Parando Postgresql..."
docker-compose -f /var/reverse-proxy/public/postgresql/docker-compose.yml down
if [ $? -ne 0 ]; then
    log "Erro ao parar Postgresql."
    send_telegram "❌ Erro ao parar o container Postgresql!"
    send_email "Erro no Backup" "Erro ao parar o container Postgresql às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container Postgresql parado com sucesso."

log "Parando container Redis..."
docker-compose -f /var/reverse-proxy/public/redis/docker-compose.yml down
if [ $? -ne 0 ]; then
    log "Erro ao parar container Redis."
    send_telegram "❌ Erro ao parar o container Redis!"
    send_email "Erro no Backup" "Erro ao parar o container Redis às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container Redis parado com sucesso."

log "Parando container CueiZap..."
docker-compose -f /var/reverse-proxy/public/chat/docker-compose.yml down
if [ $? -ne 0 ]; then
    log "Erro ao parar container CueiZap."
    send_telegram "❌ Erro ao parar o container CueiZap!"
    send_email "Erro no Backup" "Erro ao parar o container CueiZap às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container CueiZap parado com sucesso."
send_telegram "✅ Sucesso ao parar todos os containers, iniciando processo de backup!"
send_email "Sucesso ao parar containers" "Sucesso ao parar todos os containers às $(date +'%Y-%m-%d %H:%M:%S')."


log "Iniciando backup...."
# Realizar backup incremental com rsync
for SRC in "${SOURCE_DIRS[@]}"; do
    DEST="$DAILY_BACKUP$(echo $SRC | sed 's|^/|/|')"  # Destino específico para cada pasta
    mkdir -p "$DEST"

    rsync -av --delete --link-dest="$LATEST_BACKUP" "$SRC/" "$DEST/" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "Erro ao realizar backup incremental de $SRC."
        send_telegram "❌ Erro ao realizar backup incremental de $SRC!"
        send_email "Erro no Backup" "Erro ao realizar backup incremental às $(date +'%Y-%m-%d %H:%M:%S')."
        exit 1
    fi
    log "Backup incremental de $SRC concluído com sucesso."
    send_telegram "Backup incremental de $SRC concluído com sucesso."
    send_email "Sucesso no Backup" "Backup incremental de $SRC concluído com sucesso. às $(date +'%Y-%m-%d %H:%M:%S'). Dando continuidade para a limpeza e atualização dos diretórios."
done

# Atualizar o diretório do último backup
log "Atualizando diretório 'latest'..."
rm -rf "$LATEST_BACKUP"
cp -al "$DAILY_BACKUP" "$LATEST_BACKUP"

# Reiniciar containers Docker
send_telegram "🛠️ Iniciando processo de reinicialização dos containers!"
send_email "Reiniciando Containers" "Iniciando processo de reinicialização dos containers às $(date +'%Y-%m-%d %H:%M:%S')."

log "Reiniciando container postgresql..."
docker-compose -f /var/reverse-proxy/public/postgresql/docker-compose.yml up -d
if [ $? -ne 0 ]; then
    log "Erro ao reiniciar container postgresql."
    send_telegram "❌ Erro ao reiniciar o container postgresql!"
    send_email "Erro ao reiniciar container" "Erro ao reiniciar o container postgresql às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container posgresql reiniciado com sucesso."

log "Reiniciando container Redis..."
docker-compose -f /var/reverse-proxy/public/redis/docker-compose.yml up -d
if [ $? -ne 0 ]; then
    log "Erro ao reiniciar container Redis."
    send_telegram "❌ Erro ao reiniciar o container Redis!"
    send_email "Erro ao reiniciar container" "Erro ao reiniciar o container Redis às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container Redis reiniciado com sucesso."

log "Reiniciando container calcom..."
docker-compose -f /var/reverse-proxy/public/agenda/docker/docker-compose.yaml up -d
if [ $? -ne 0 ]; then
    log "Erro ao reiniciar container calcom."
    send_telegram "❌ Erro ao reiniciar o container calcom!"
    send_email "Erro ao reiniciar container" "Erro ao reiniciar o container calcom às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container calcom reiniciado com sucesso."

log "Reiniciando container drive..."
docker-compose -f /var/reverse-proxy/public/drive/docker-compose.yml up -d
if [ $? -ne 0 ]; then
    log "Erro ao reiniciar container drive."
    send_telegram "❌ Erro ao reiniciar o container drive!"
    send_email "Erro ao reiniciar container" "Erro ao reiniciar o container drive às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container drive reiniciado com sucesso."

log "Reiniciando container Evo..."
docker-compose -f /var/reverse-proxy/public/evo/docker-compose.yml up -d
if [ $? -ne 0 ]; then
    log "Erro ao reiniciar container Evo."
    send_telegram "❌ Erro ao reiniciar o container Evo!"
    send_email "Erro ao reiniciar container" "Erro ao reiniciar o container Evo às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container evolution reiniciado com sucesso."

log "Reiniciando container N8N..."
docker-compose -f /var/reverse-proxy/public/n8nfila/docker-compose.yml up -d
if [ $? -ne 0 ]; then
    log "Erro ao reiniciar container N8N."
    send_telegram "❌ Erro ao reiniciar o container N8N!"
    send_email "Erro ao reiniciar container" "Erro ao reiniciar o container N8N às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container N8N reiniciado com sucesso."

log "Reiniciando container Odoo..."
docker-compose -f /var/reverse-proxy/public/odoo/docker-compose.yml up -d
if [ $? -ne 0 ]; then
    log "Erro ao reiniciar container Odoo."
    send_telegram "❌ Erro ao reiniciar o container Odoo!"
    send_email "Erro ao reiniciar container" "Erro ao reiniciar o container Odoo às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container Odoo reiniciado com sucesso."

log "Reiniciando container CueiZap..."
docker-compose -f /var/reverse-proxy/public/chat/docker-compose.yml up -d
if [ $? -ne 0 ]; then
    log "Erro ao reiniciar container CueiZap."
    send_telegram "❌ Erro ao reiniciar o container CueiZap!"
    send_email "Erro ao reiniciar container" "Erro ao reiniciar o container CueiZap às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container CueiZap reiniciado com sucesso."

log "Reiniciando container nginx..."
docker-compose -f /var/reverse-proxy/docker-compose.yml up -d
if [ $? -ne 0 ]; then
    log "Erro ao reiniciar container nginx."
    send_telegram "❌ Erro ao reiniciar o container Nginx!"
    send_email "Erro ao reiniciar container" "Erro ao reiniciar o container Nginx às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Container nginx reiniciado com sucesso."
send_telegram "✅ Sucesso ao reiniciar todos os containers"
send_email "Sucesso ao reiniciar containers" "Sucesso ao reiniciar todos os containers às $(date +'%Y-%m-%d %H:%M:%S'). Dando continuidade ao processo de remover backups antigos"

# Remover backups antigos (mais de 7 dias)
log "Removendo backups antigos..."
find "$BACKUP_DIR/daily" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;

log "Backups antigos removidos."

log "Compactando backup diário..."
send_telegram "🛠️ Compactando backup diário..."
send_email "Compactando Backup" "Compactando backup diário às $(date +'%Y-%m-%d %H:%M:%S')."
tar -czf "$DAILY_BACKUP.tar.gz" -C "$DAILY_BACKUP" .
if [ $? -ne 0 ]; then
    log "Erro ao compactar o backup diário."
    send_telegram "❌ Erro ao compactar o backup diário."
    send_email "Erro ao Compactar" "Erro ao compactar o backup diário às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Backup diário compactado com sucesso: $DAILY_BACKUP.tar.gz"
send_telegram "✅ Backup diário compactado com sucesso: $DAILY_BACKUP.tar.gz"
send_email "Backup Compactado" "Compactando backup diário às $(date +'%Y-%m-%d %H:%M:%S'). Iniciando testes de conectividade com Google Drive"

# Atualizar o caminho para o backup compactado
DAILY_BACKUP="$DAILY_BACKUP.tar.gz"

log "Testando conectividade com o Google Drive..."
rclone lsd "$RCLONE_REMOTE" >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "Erro: Não foi possível acessar o Google Drive. Verifique a configuração do Rclone."
    send_telegram "❌ Erro: Não foi possível acessar o Google Drive. Verifique a configuração do Rclone."
    send_email "Erro ao Conectar ao Drive" "Erro: Não foi possível acessar o Google Drive às $(date +'%Y-%m-%d %H:%M:%S'). Verifique a configuração do Rclone."
    exit 1
fi
log "Conectividade com o Google Drive confirmada."

log "Enviando backup para o Google Drive..."
rclone sync "$DAILY_BACKUP" "$RCLONE_REMOTE/$BACKUP_DATE" --progress -vv >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "Erro ao enviar backup para o Google Drive. Verifique o log em $LOG_FILE."
    send_telegram "❌ Erro ao enviar backup para o Google Drive. Verifique o log em $LOG_FILE."
    send_email "Erro ao enviar backup" "Erro ao enviar backup para o Google Drive às $(date +'%Y-%m-%d %H:%M:%S'). Verifique o log em $LOG_FILE."
    exit 1
fi
log "Backup enviado com sucesso para o Google Drive."
send_telegram "✅ Backup enviado com sucesso para o Google Drive.."
send_email "Sucesso ao enviar backup" "Backup enviado com sucesso para o Google Drive às $(date +'%Y-%m-%d %H:%M:%S'). Prosseguindo para limpeza dos arquivos temporarios e diretorios"


log "Limpando os arquivos da pasta 'daily'..."
rm -rf "$BACKUP_DIR/daily"/*
if [ $? -ne 0 ]; then
    log "Erro ao limpar a pasta 'daily'."
    send_email "Erro limpando pasta 'daily'" "Erro ao limpar a pasta 'daily' às $(date +'%Y-%m-%d %H:%M:%S')."
    exit 1
fi
log "Pasta 'daily' limpa com sucesso."

log "Backup concluído com sucesso."
send_telegram "✅ Backup concluído com sucesso... ✅"
send_email "Backup concluído" "Backup concluído com sucesso às $(date +'%Y-%m-%d %H:%M:%S')."
