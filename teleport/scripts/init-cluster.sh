#!/usr/bin/env sh
set -eu

echo "Waiting for Teleport Auth API..."
until tctl status >/dev/null 2>&1; do
  sleep 2
done

echo "Applying demo roles..."
tctl create -f /opt/teleport-lab/roles/lab-admin.yaml
tctl create -f /opt/teleport-lab/roles/lab-user.yaml

echo
echo "Cluster ready."
tctl status
echo
echo "Next: run /opt/teleport-lab/scripts/create-users.sh"
