#!/bin/bash
VIP="10.8.0.100"

if ping -c 1 -W 1 $VIP > /dev/null 2>&1; then
    echo "VIP $VIP está ativo"
    CURRENT_MASTER=$(ip neigh show | grep "$VIP" | awk '{print $3}')
    echo "VIP está em: $CURRENT_MASTER"
else
    echo "VIP $VIP está inativo"
    exit 1
fi