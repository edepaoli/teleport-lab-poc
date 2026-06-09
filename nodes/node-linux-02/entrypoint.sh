#!/usr/bin/env bash
set -euo pipefail

NODE_NAME="${NODE_NAME:-lab-linux-02}"
NODE_LABELS="${NODE_LABELS:-env=lab,os=linux,criticality=medium,group=standard}"
TELEPORT_JOIN_TOKEN="${TELEPORT_JOIN_TOKEN:-local-lab-join-token-change-me}"

mkdir -p /etc/teleport /var/lib/teleport /var/log/teleport
echo "$(date -Is) ${NODE_NAME} container bootstrap started" >> /var/log/node-bootstrap.log

IFS=',' read -ra LABEL_PAIRS <<< "$NODE_LABELS"
{
  cat <<YAML
version: v3
teleport:
  nodename: ${NODE_NAME}
  data_dir: /var/lib/teleport
  auth_token: ${TELEPORT_JOIN_TOKEN}
  auth_server: teleport-auth:3025
  log:
    output: /var/log/teleport/teleport.log
    severity: INFO
    format:
      output: text
auth_service:
  enabled: "no"
proxy_service:
  enabled: "no"
ssh_service:
  enabled: "yes"
  labels:
YAML
  for pair in "${LABEL_PAIRS[@]}"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    printf '    %s: "%s"\n' "$key" "$value"
  done
} > /etc/teleport/teleport.yaml

exec teleport start --config=/etc/teleport/teleport.yaml
