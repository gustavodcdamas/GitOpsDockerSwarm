#!/bin/bash
TYPE=$1
NAME=$2
STATE=$3

echo "$(date): $TYPE $NAME changed to $STATE" >> /var/log/keepalived-notify.log

case $STATE in
    "MASTER")
        echo "$(date): Becoming MASTER for VIP" >> /var/log/keepalived-notify.log
        # Executar ações quando se tornar master
        ;;
    "BACKUP") 
        echo "$(date): Becoming BACKUP" >> /var/log/keepalived-notify.log
        ;;
    "FAULT")
        echo "$(date): Entering FAULT state" >> /var/log/keepalived-notify.log
        ;;
    *)
        echo "$(date): Unknown state: $STATE" >> /var/log/keepalived-notify.log
        ;;
esac