#!/usr/bin/env sh
set -eu

echo "== Teleport cluster =="
tctl status
echo
echo "== Users =="
tctl users ls
echo
echo "== Nodes =="
tctl nodes ls || true
echo
echo "== Tokens =="
tctl tokens ls || true
