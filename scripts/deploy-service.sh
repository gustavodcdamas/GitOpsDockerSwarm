#!/bin/bash
set -e  # Sai imediatamente se um comando falhar

# Função para exibir mensagem de erro e sair
error_exit() {
  echo "Erro: $1" >&2
  exit 1
}

# Processar argumentos
while getopts "r:s:h:u:" opt; do
  case "$opt" in
    r) REGION="$OPTARG" ;;
    s) SERVICE="$OPTARG" ;;
    h) HOST="$OPTARG" ;;
    u) USER="$OPTARG" ;;
    \?)
      echo "Uso: $0 -r <região> -s <serviço> -h <host> -u <usuário>"
      exit 1
      ;;
  esac
done

# Verificar se todos os argumentos obrigatórios foram fornecidos
if [ -z "$REGION" ] || [ -z "$SERVICE" ] || [ -z "$HOST" ] || [ -z "$USER" ]; then
  echo "Erro: Todos os argumentos (-r, -s, -h, -u) são obrigatórios."
  exit 1
fi

echo "Iniciando deploy do serviço $SERVICE na região $REGION..."

# Montar o caminho para os arquivos de configuração
CONFIG_PATH="environments/$REGION/$SERVICE"

# Verificar se o diretório de configuração existe
if [ ! -d "$CONFIG_PATH" ]; then
  error_exit "Diretório de configuração não encontrado: $CONFIG_PATH"
fi

# Comando SSH para executar no servidor remoto
SSH_COMMAND=" cd /opt/gitops; git pull origin main; cd $CONFIG_PATH; # Validar compose file docker-compose config # Deploy com rollback automático docker-compose up -d || docker-compose up -d --force-recreate "

# Executar o comando SSH
ssh -o StrictHostKeyChecking=no $USER@$HOST "$SSH_COMMAND"

echo "Deploy do serviço $SERVICE na região $REGION concluído."