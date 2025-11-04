#!/bin/bash
# failover-dns.sh

CLOUDFLARE_API_TOKEN="seu_token"
ZONE_ID="sua_zone_id"
RECORD_ID="seu_record_id"
DOMAIN="app.seudominio.com"

# Verificar saúde do servidor local
if curl -s --max-time 5 "http://localhost:8080/health" | grep -q "healthy"; then
    # Servidor saudável, garantir que é o primário no DNS
    CURRENT_IP=$(curl -s "http://ifconfig.me")
    curl -X PATCH "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
         -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
         -H "Content-Type: application/json" \
         --data '{"type":"A","name":"'"$DOMAIN"'","content":"'"$CURRENT_IP"'","proxied":true,"ttl":1}'
else
    echo "Servidor não saudável, não atualizando DNS"
fi