#!/usr/bin/env sh
set -eu

SERVICE="${OPENBAO_COMPOSE_SERVICE:-openbao}"
BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}"
BOOTSTRAP_DIR="${OPENBAO_BOOTSTRAP_DIR:-vault-log/openbao/bootstrap}"
INIT_FILE="${BOOTSTRAP_DIR}/init.json"
ROOT_TOKEN_FILE="${BOOTSTRAP_DIR}/root-token"

mkdir -p "${BOOTSTRAP_DIR}"
chmod 700 "${BOOTSTRAP_DIR}"

docker compose exec -T -u 0 "${SERVICE}" sh -c 'mkdir -p /openbao/data && chown -R openbao:openbao /openbao/data' >/dev/null

bao() {
  docker compose exec -T -e BAO_ADDR="${BAO_ADDR}" "${SERVICE}" bao "$@"
}

bao_root() {
  docker compose exec -T -e BAO_ADDR="${BAO_ADDR}" -e BAO_TOKEN="${ROOT_TOKEN}" "${SERVICE}" bao "$@"
}

status_text="$(bao status 2>&1 || true)"

if printf '%s\n' "${status_text}" | grep -q 'Initialized[[:space:]]*false'; then
  echo "Initializing OpenBao..."
  bao operator init -key-shares=1 -key-threshold=1 -format=json > "${INIT_FILE}"
  chmod 600 "${INIT_FILE}"
else
  echo "OpenBao already initialized."
fi

if [ ! -f "${INIT_FILE}" ]; then
  echo "Missing ${INIT_FILE}; cannot unseal without the original unseal key." >&2
  exit 1
fi

UNSEAL_KEY="$(awk -F'"' 'found && NF >= 2 {print $2; exit} /"unseal_keys_b64"/ {found=1}' "${INIT_FILE}")"
ROOT_TOKEN="$(awk -F'"' '/"root_token"/ {print $4; exit}' "${INIT_FILE}")"

if [ -z "${UNSEAL_KEY}" ] || [ -z "${ROOT_TOKEN}" ]; then
  echo "Could not parse unseal key or root token from ${INIT_FILE}." >&2
  exit 1
fi

printf '%s\n' "${ROOT_TOKEN}" > "${ROOT_TOKEN_FILE}"
chmod 600 "${ROOT_TOKEN_FILE}"

status_text="$(bao status 2>&1 || true)"
if printf '%s\n' "${status_text}" | grep -q 'Sealed[[:space:]]*true'; then
  echo "Unsealing OpenBao..."
  bao operator unseal "${UNSEAL_KEY}" >/dev/null
else
  echo "OpenBao already unsealed."
fi

if ! bao_root secrets list 2>/dev/null | awk '{print $1}' | grep -qx 'secret/'; then
  echo "Enabling kv-v2 at secret/..."
  bao_root secrets enable -path=secret kv-v2 >/dev/null
else
  echo "kv-v2 secret/ already enabled."
fi

echo "Writing demo lab secrets..."
bao_root kv put secret/lab/linux-01/root username=root password=demo-root-01 >/dev/null
bao_root kv put secret/lab/linux-02/admin username=admin password=demo-admin-02 >/dev/null
bao_root kv put secret/lab/linux-02/mario username=mario password=mariomariomario. >/dev/null
bao_root kv put secret/lab/linux-03/labuser username=labuser password=demo-labuser-03 >/dev/null

echo "Writing lab-readonly policy..."
bao_root policy write lab-readonly - >/dev/null <<'POLICY'
path "secret/data/lab/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/lab/*" {
  capabilities = ["read", "list"]
}
POLICY

echo "OpenBao bootstrap complete."
echo "Sensitive bootstrap files are stored locally under ${BOOTSTRAP_DIR} and ignored by Git."
