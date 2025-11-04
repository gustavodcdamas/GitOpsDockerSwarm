#!/bin/bash
# /etc/keepalived/check_services.sh

# Verificar se Docker está rodando
if ! systemctl is-active --quiet docker; then
    exit 1
fi

# Verificar saúde dos containers principais
if ! docker ps | grep -q "healthy"; then
    exit 1
fi

# Verificar conectividade com banco de dados
if ! nc -z localhost 3306 || ! nc -z localhost 5432; then
    exit 1
fi

# Check if we can access swarm
if ! timeout 5 docker node ls > /dev/null 2>&1; then
    echo "Cannot access swarm"
    exit 1
fi

# Verificar se o nó é manager
if ! docker node ls > /dev/null 2>&1; then
    exit 1
fi

# Verificar se o nó está pronto
NODE_STATE=$(timeout 5 docker node inspect self --format '{{.Status.State}}' 2>/dev/null || echo "unknown")
if [ "$NODE_STATE" != "ready" ]; then
    echo "Node not ready: $NODE_STATE"
    exit 1
fi

if ! systemctl is-active --quiet docker; then 
    exit 1; 
fi

if ! timeout 5 docker node ls > /dev/null 2>&1; then
 exit 1; 
fi

exit 0

# Verificar conectividade com outros managers (opcional)
NODE_ROLE=$(timeout 5 docker node inspect self --format '{{.Spec.Role}}' 2>/dev/null || echo "unknown")
if [ "$NODE_ROLE" != "manager" ]; then
    echo "Not a manager: $NODE_ROLE"
    exit 1
fi

exit 0