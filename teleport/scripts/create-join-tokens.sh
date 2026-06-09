#!/usr/bin/env sh
set -eu

echo "This PoC uses a static join token from teleport/auth/teleport.yaml:"
echo "  local-lab-join-token-change-me"
echo
echo "For a less static local test, create short-lived tokens manually, for example:"
echo "  tctl tokens add --type=node --ttl=1h"
echo "  tctl tokens add --type=proxy --ttl=1h"
echo
echo "Then update the proxy and node configs or environment values before starting them."
