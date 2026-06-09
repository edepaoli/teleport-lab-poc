#!/usr/bin/env sh
set -eu

BASE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

mkdir -p "$BASE_DIR/proxy-a/certs" "$BASE_DIR/proxy-b/certs"

openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout "$BASE_DIR/proxy-a/certs/proxy-a.key" \
  -out "$BASE_DIR/proxy-a/certs/proxy-a.crt" \
  -subj /CN=localhost \
  -addext subjectAltName=DNS:localhost,IP:127.0.0.1

openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout "$BASE_DIR/proxy-b/certs/proxy-b.key" \
  -out "$BASE_DIR/proxy-b/certs/proxy-b.crt" \
  -subj /CN=localhost \
  -addext subjectAltName=DNS:localhost,IP:127.0.0.1

echo "Generated local self-signed certificates for proxy-a and proxy-b."
