#!/bin/bash
# DDNS hostname (can be any provider)
DDNS_HOST="changeme.duckdns.org"
# Port you want to protect
PORT=81
# Protocol (tcp or udp)
PROTO="tcp"

# Resolve current IP from DDNS
CURRENT_IP=$(dig +short "$DDNS_HOST" | tail -n1)

# File storing the last applied IP
IP_FILE="/var/run/ufw-ddns-$DDNS_HOST"

# If no IP, exit
if [ -z "$CURRENT_IP" ]; then
  echo "[$(date)] Could not resolve $DDNS_HOST"
  exit 1
fi

# If same IP already applied, exit
if [ -f "$IP_FILE" ]; then
  OLD_IP=$(cat "$IP_FILE")
  if [ "$OLD_IP" == "$CURRENT_IP" ]; then
    echo "[$(date)] IP unchanged ($CURRENT_IP)"
    exit 0
  fi
fi

# If OLD_IP exists, try to delete it; otherwise wipe all rules for PORT/PROTO
if [ -n "${OLD_IP:-}" ]; then
  if sudo ufw status | grep -q "$OLD_IP" | grep -q "$PORT/$PROTO"; then
    sudo ufw delete allow from "$OLD_IP" to any port "$PORT" proto "$PROTO"
    echo "[$(date)] Old rule with $OLD_IP removed"
  else
    echo "[$(date)] Old IP $OLD_IP not present in UFW, deleting all rules for $PORT/$PROTO"
    EXISTING_RULES=$(sudo ufw status numbered | grep -v "(v6)" | grep "$PORT/$PROTO" | awk -F'[][]' '{print $2}' | sort -rn)
    for RULE_NUM in $EXISTING_RULES; do
      sudo ufw --force delete "$RULE_NUM"
    done
  fi
else
  echo "[$(date)] No previous IP stored, deleting all rules for $PORT/$PROTO"
  EXISTING_RULES=$(sudo ufw status numbered | grep -v "(v6)" | grep "$PORT/$PROTO" | awk -F'[][]' '{print $2}' | sort -rn)
  for RULE_NUM in $EXISTING_RULES; do
    sudo ufw --force delete "$RULE_NUM"
  done
fi

# Add new rule
sudo ufw allow from "$CURRENT_IP" to any port "$PORT" proto "$PROTO"

# Save new IP
echo "$CURRENT_IP" | sudo tee "$IP_FILE" >/dev/null

echo "[$(date)] Updated UFW rule: $CURRENT_IP -> port $PORT/$PROTO"
