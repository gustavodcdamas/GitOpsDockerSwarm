#!/bin/bash

EUROPE_IP="your.europe.ip"
USA_IP="your.usa.ip"

check_server() {
    local server_ip=$1
    local server_name=$2
    
    if curl -s --connect-timeout 5 "http://$server_ip:8080/health" | grep -q "healthy"; then
        echo "$server_name is healthy"
        return 0
    else
        echo "$server_name is down!"
        return 1
    fi
}

# Monitor Europe
if ! check_server $EUROPE_IP "Europe"; then
    echo "Failing over to USA..."
    # Atualizar Cloudflare DNS para apontar apenas para USA
    # ou desativar pool Europe no Load Balancer
fi

# Monitor USA
if ! check_server $USA_IP "USA"; then
    echo "Failing over to Europe..."
    # Atualizar Cloudflare DNS para apontar apenas para Europe
fi