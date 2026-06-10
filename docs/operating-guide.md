# Operating Guide

## Bootstrap

```sh
cp .env.example .env
./teleport/scripts/generate-local-certs.sh
docker compose up -d --build
docker compose exec teleport-auth /opt/teleport-lab/scripts/init-cluster.sh
docker compose exec teleport-auth /opt/teleport-lab/scripts/create-users.sh
```

## Verifiche

```sh
docker compose ps
docker compose exec teleport-auth /opt/teleport-lab/scripts/show-status.sh
tsh login --proxy=localhost:3080 --user=mario.rossi --insecure
tsh ls
```

## Test accessi aggiornati

```sh
tsh ssh labuser@lab-linux-02
tsh ssh mario@lab-linux-02
tsh ssh root@lab-linux-02
```

Con `admin.lab`:

```sh
tsh ssh root@vault-log
tsh ssh admin@vault-log
```

## Rotazione token PoC

Il token statico e' comodo per una demo locale, ma non va riusato in ambienti condivisi. Cambia il valore in:

- `.env`
- `teleport/auth/teleport.yaml`
- `teleport/proxy-a/teleport.yaml`
- `teleport/proxy-b/teleport.yaml`

Poi ricrea i container e i volumi:

```sh
docker compose down -v
docker compose up -d --build
```

## Debug

```sh
docker compose logs -f teleport-auth
docker compose logs -f teleport-proxy-a
docker compose logs -f teleport-proxy-b
docker compose logs -f lab-linux-01
docker compose logs -f vault-log-rsyslog
```

Se `tsh login` fallisce per TLS locale, usa `--insecure`.

## Log centralizzati rsyslog

```sh
tail -f vault-log/logs/rsyslog/all.log
tail -f vault-log/logs/rsyslog/by-host/vault-log-fluent-bit.log
```

Rsyslog riceve da Fluent Bit i log Teleport Auth/Proxy, gli audit events e i file log dei nodi. La porta e' esposta anche sull'host come `localhost:5514` TCP/UDP.

Dal nodo Teleport `vault-log`:

```sh
tsh ssh root@vault-log
ls -la /vault-log/logs
tail -f /vault-log/logs/rsyslog/all.log
```

## OpenBao

OpenBao non usa un root token demo statico: il vault va inizializzato, unsealed e configurato.

```sh
./vault-log/openbao/bootstrap-openbao.sh
```

Lo script salva i materiali sensibili in `vault-log/openbao/bootstrap/`, directory ignorata da Git. Dopo il bootstrap:

```sh
docker compose exec -T -e BAO_ADDR=http://127.0.0.1:8200 openbao bao status
docker compose exec -T -e BAO_ADDR=http://127.0.0.1:8200 -e BAO_TOKEN="$(cat vault-log/openbao/bootstrap/root-token)" openbao bao kv list secret/lab
```
