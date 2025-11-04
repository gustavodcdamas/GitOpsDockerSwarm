#!/bin/bash
# /opt/scripts/optimize-firewall.sh

echo "=== OTIMIZANDO FIREWALL ==="

# Reset para começar limpo
ufw --force reset

# Permitir pacotes de retorno em conexões estabelecidas
ufw allow in on eth0 from any to any state RELATED,ESTABLISHED comment 'Permitir conexões estabelecidas'
ufw allow in on wg0 from any to any state RELATED,ESTABLISHED comment 'Permitir retorno WireGuard'

# Permitir apenas tráfego necessário de clientes
ufw allow from 10.9.0.0/24 to 172.0.0.0/24 port 22,80,443,3306,5432,6379,5672,15672 proto tcp
ufw deny from 10.9.0.0/24 to any port 2377,7946,4789 comment 'Bloquear acesso Swarm de clientes'


# Regras básicas
ufw default deny incoming
ufw default deny forward
ufw default allow outgoing

# Serviços essenciais
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# WireGuard
ufw allow 51820/udp comment 'WireGuard IPSec'
ufw allow 51821/udp comment 'WireGuard Clientes'

# Docker Swarm (se usar)
ufw allow 2377/tcp comment 'Docker Swarm'
ufw allow 7946/tcp comment 'Docker Swarm Discovery'
ufw allow 7946/udp comment 'Docker Swarm Discovery'
ufw allow 4789/udp comment 'Docker Overlay Network'

# GlusterFS (se usar)
ufw allow 24007/tcp comment 'GlusterFS Daemon'
ufw allow 24008/tcp comment 'GlusterFS Management'
ufw allow 49152:49251/tcp comment 'GlusterFS Bricks'

# ============ REGRAS POR REDE ============

# Rede IPSec (10.8.0.0/24) - Acesso total entre servidores
ufw allow from 10.8.0.0/24 to any comment 'Rede IPSec Interna'

# Rede Clientes VPN (10.9.0.0/24) - Acesso controlado
ufw allow from 10.9.0.0/24 to 10.8.0.0/24 comment 'VPN Clientes para IPSec'
ufw allow from 10.9.0.0/24 to 172.3.0.0/24 comment 'VPN Clientes para Rede Docker'

# Bancos apenas para VPN
ufw allow from 10.9.0.0/24 to any port 3306 comment 'MySQL apenas VPN'
ufw allow from 10.9.0.0/24 to any port 5432 comment 'PostgreSQL apenas VPN'
ufw allow from 10.9.0.0/24 to any port 6379 comment 'Redis apenas VPN'
ufw allow from 10.9.0.0/24 to any port 5672 comment 'RabbitMQ apenas VPN'
ufw allow from 10.9.0.0/24 to any port 15672 comment 'RabbitMQ UI apenas VPN'

# Bloquear acesso público aos bancos
ufw deny 3306/tcp comment 'Bloquear MySQL público'
ufw deny 5432/tcp comment 'Bloquear PostgreSQL público'
ufw deny 6379/tcp comment 'Bloquear Redis público'
ufw deny 5672/tcp comment 'Bloquear RabbitMQ público'
ufw deny 15672/tcp comment 'Bloquear RabbitMQ UI público'

# Interfaces específicas
ufw allow in on wg0 comment 'WireGuard Interface'
ufw allow in on docker0 comment 'Docker Interface'
ufw allow in on docker_gwbridge comment 'Docker GW Bridge'

# IPv6 - Bloquear tudo (mais seguro)
ufw deny from ::/0

# Limpar regras existentes
ufw reset

# Ativar logging
ufw logging high

# Política padrão
ufw default deny incoming
ufw default allow outgoing

# --------------------
# Regras públicas
# --------------------
ufw allow 22/tcp comment "SSH"
ufw limit 22/tcp comment "SSH - limita brute force"
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS"

# SMTP e IMAP (para clientes externos)
ufw allow 25/tcp comment "SMTP"
ufw allow 465/tcp comment "SMTPS"
ufw allow 587/tcp comment "SMTP Submission"
ufw allow 143/tcp comment "IMAP"
ufw allow 993/tcp comment "IMAPS"

# WireGuard
ufw allow 51820/udp comment "WireGuard IPSec"
ufw allow 51821/udp comment "WireGuard Clientes"

# Docker Swarm (necessário para cluster)
ufw allow 2377/tcp comment "Swarm manager"
ufw allow 7946/tcp comment "Swarm node discovery"
ufw allow 7946/udp comment "Swarm node discovery"
ufw allow 4789/udp comment "Overlay network"

# GlusterFS
ufw allow 24007/tcp comment "GlusterFS daemon"
ufw allow 24008/tcp comment "GlusterFS management"
ufw allow 49152:49251/tcp comment "GlusterFS bricks"

# --------------------
# Regras VPN / internas
# --------------------
# Permitir serviços internos apenas via VPN (WireGuard)
ufw allow from 10.8.0.0/24 to any comment "Rede IPSec interna"
ufw allow from 10.9.0.0/24 to any comment "Rede VPN clientes"

# Serviços de banco/cache apenas via VPN
ufw allow from 10.8.0.0/24 to any port 3306,5432,6379,5672,15672 comment "MySQL/Postgres/Redis/RabbitMQ apenas VPN"
ufw allow from 10.9.0.0/24 to any port 3306,5432,6379,5672,15672 comment "MySQL/Postgres/Redis/RabbitMQ apenas VPN"

# Interfaces específicas
ufw allow in on wg0 comment "WireGuard interface"
ufw allow in on docker0 comment "Docker local bridge"
ufw allow in on docker_gwbridge comment "Docker GW bridge"

# --------------------
# Bloqueios explícitos públicos
# --------------------
ufw deny in 3306/tcp comment "Bloquear MySQL público"
ufw deny in 5432/tcp comment "Bloquear PostgreSQL público"
ufw deny in 6379/tcp comment "Bloquear Redis público"
ufw deny in 5672/tcp comment "Bloquear RabbitMQ público"
ufw deny in 15672/tcp comment "Bloquear RabbitMQ UI público"

# --------------------
# IPv6 (mesma lógica)
# --------------------
ufw allow 22/tcp comment "SSH v6"
ufw limit 22/tcp comment "SSH v6 brute force limit"
ufw allow 80/tcp comment "HTTP v6"
ufw allow 443/tcp comment "HTTPS v6"
ufw allow 51820/udp comment "WireGuard IPSec v6"
ufw allow 51821/udp comment "WireGuard Clientes v6"
ufw allow 2377/tcp comment "Swarm manager v6"
ufw allow 7946/tcp comment "Swarm discovery v6"
ufw allow 7946/udp comment "Swarm discovery v6"
ufw allow 4789/udp comment "Overlay network v6"

ufw allow in on wg0 comment "WireGuard interface v6"
ufw allow in on docker0 comment "Docker local bridge v6"
ufw allow in on docker_gwbridge comment "Docker GW bridge v6"

ufw deny in 3306/tcp comment "Bloquear MySQL público v6"
ufw deny in 5432/tcp comment "Bloquear PostgreSQL público v6"
ufw deny in 6379/tcp comment "Bloquear Redis público v6"
ufw deny in 5672/tcp comment "Bloquear RabbitMQ público v6"
ufw deny in 15672/tcp comment "Bloquear RabbitMQ UI público v6"

# --------------------
# Ativar UFW
# --------------------
ufw enable

echo "=== ATIVANDO FIREWALL ==="
ufw --force enable

echo "=== STATUS FINAL ==="
ufw status verbose