#!/bin/bash
set -e

# ===============================
# VARIÁVEIS BÁSICAS
# ===============================
GLUSTER_PEERS=("10.8.0.2" "10.8.0.1") # adicione o IP privado dos peers aqui
BRICK_DIR="/data/gluster/brick1"
VOLUME_NAME="shared_data"

# ===============================
# INSTALAÇÃO E CONFIGURAÇÃO
# ===============================
echo "[1/6] Atualizando pacotes..."
apt update -y && apt upgrade -y

echo "[2/6] Instalando GlusterFS..."
apt install -y glusterfs-server

echo "[3/6] Habilitando e iniciando o serviço..."
systemctl enable glusterd
systemctl start glusterd
systemctl status glusterd --no-pager

echo "[4/6] Configurando firewall (se houver ufw)..."
if command -v ufw &> /dev/null; then
  ufw allow 24007/tcp
  ufw allow 24008/tcp
  ufw allow 49152:49251/tcp
fi

echo "[5/6] Criando diretório de dados..."
mkdir -p $BRICK_DIR
chown -R root:root $BRICK_DIR

echo "[6/6] Configuração base concluída!"
echo ""
echo "Agora, em apenas UM dos nós, execute o seguinte comando para formar o cluster:"
echo ""
echo "  gluster peer probe 10.8.0.3"
echo ""
echo "Verifique com:"
echo "  gluster peer status"
echo ""
echo "Depois, crie o volume com:"
echo "  gluster volume create ${VOLUME_NAME} replica 2 transport tcp 10.8.0.2:${BRICK_DIR} 10.8.0.3:${BRICK_DIR} force"
echo ""
echo "E inicie com:"
echo "  gluster volume start ${VOLUME_NAME}"
echo ""
echo "Monte o volume localmente em /mnt/gluster com:"
echo "  mkdir -p /mnt/gluster && mount -t glusterfs 10.8.0.2:/${VOLUME_NAME} /mnt/gluster"
