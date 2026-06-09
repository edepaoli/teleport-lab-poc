# Teleport Lab PoC

PoC locale e containerizzata per simulare un mini laboratorio con accesso centralizzato tramite Teleport Community Edition.

## Componenti

- `teleport-auth`: Auth server centrale, storage locale persistente, audit events e session recordings su filesystem.
- `teleport-proxy-a`: primo gateway HTTPS/SSH su `https://localhost:3080`.
- `teleport-proxy-b`: secondo gateway HTTPS/SSH su `https://localhost:3180`.
- `lab-linux-01`, `lab-linux-02`, `lab-linux-03`, `lab-admin-01`, `vault-log`: nodi Linux simulati con Teleport node service.
- `openbao`: vault locale per simulare un futuro repository segreti.
- `vault-log-rsyslog`: server rsyslog centrale, riceve log via TCP/UDP 514.
- `fluent-bit`: shipper che inoltra log Teleport, audit e nodi a `vault-log-rsyslog`.

## Avvio rapido

```sh
cp .env.example .env
./teleport/scripts/generate-local-certs.sh
docker compose up -d --build
docker compose exec teleport-auth /opt/teleport-lab/scripts/init-cluster.sh
docker compose exec teleport-auth /opt/teleport-lab/scripts/create-users.sh
```

Apri:

- https://localhost:3080
- https://localhost:3180

I certificati dei proxy sono self-signed: il browser e `tsh` richiederanno di accettare il rischio locale.

## Login CLI

Installa `tsh` della stessa major version di Teleport configurata in `.env`, poi:

```sh
tsh login --proxy=localhost:3080 --user=mario.rossi --insecure
tsh ls
tsh ssh labuser@lab-linux-01
```

Secondo gateway:

```sh
tsh login --proxy=localhost:3180 --user=admin.lab --insecure
```

## Test RBAC attesi

`mario.rossi` ha ruolo `lab-user`:

```sh
tsh ssh labuser@lab-linux-01
tsh ssh labuser@lab-linux-02
tsh ssh mario@lab-linux-02
tsh ssh root@lab-linux-02
tsh ssh labuser@lab-admin-01     # deve fallire
tsh ssh mario@lab-linux-01       # il ruolo lo consente, ma l'utente Linux esiste solo su lab-linux-02
```

`admin.lab` ha ruolo `lab-admin`:

```sh
tsh ssh root@lab-linux-01
tsh ssh admin@lab-admin-01
tsh ssh labuser@lab-linux-03
tsh ssh root@vault-log
tsh ssh admin@vault-log
```

## MFA, WebAuthn e YubiKey

La configurazione locale usa autenticazione `local` con `second_factor: on` e WebAuthn predisposto con `rp_id: localhost`.

Flusso tipico:

1. Esegui `create-users.sh`.
2. Apri il link di enrollment stampato dallo script.
3. Crea password locale.
4. Quando Teleport propone MFA, registra una passkey, Touch ID o YubiKey compatibile WebAuthn.
5. Accedi da browser o da `tsh login --proxy=localhost:3080 --user=<utente> --insecure`.

Note:

- TOTP usa codici temporanei da app authenticator.
- WebAuthn usa passkey o chiavi hardware come YubiKey.
- Passwordless WebAuthn richiede impostazioni e compatibilita browser piu stringenti.
- In localhost con certificati self-signed possono comparire warning browser; per produzione serve DNS reale e TLS valido.
- Nota Teleport 17: il cluster rifiuta `second_factor: off`. Per una demo password-only usare una versione precedente o una configurazione diversa dedicata a laboratorio.

## Log e audit

Log servizi:

```sh
docker compose logs -f teleport-auth
docker compose logs -f teleport-proxy-a
docker compose logs -f teleport-proxy-b
docker compose logs -f vault-log-rsyslog
```

File locali:

- `vault-log/logs/teleport-auth/teleport.log`
- `vault-log/logs/teleport-proxy-a/teleport.log`
- `vault-log/logs/teleport-proxy-b/teleport.log`
- `vault-log/logs/nodes/<node>/node-bootstrap.log`
- `vault-log/logs/nodes/<node>/teleport/teleport.log`
- `vault-log/logs/audit/events/`
- `vault-log/logs/audit/sessions/`
- `vault-log/logs/rsyslog/all.log`
- `vault-log/logs/rsyslog/by-host/<host>.log`

Entrando via Teleport nel nodo `vault-log`, gli stessi log sono montati in:

- `/vault-log/logs/`
- `/vault-log/logs/rsyslog/all.log`
- `/vault-log/logs/rsyslog/by-host/<host>.log`

Il server rsyslog ascolta anche dall'host su:

- TCP `localhost:5514`
- UDP `localhost:5514`

Flusso log:

```text
Teleport/Auth/Proxy files + audit events + node logs -> Fluent Bit -> rsyslog TCP 514 -> vault-log/logs/rsyslog/
```

## OpenBao demo

OpenBao e' incluso come componente futuro per password vaulting, non integrato automaticamente con Teleport e non usato come log store.

```sh
export BAO_ADDR=http://127.0.0.1:8200
export BAO_TOKEN=dev-root-token
bao secrets enable -path=secret kv-v2
bao kv put secret/lab/linux-01/root username=root password=demo-root-01
bao kv put secret/lab/linux-02/admin username=admin password=demo-admin-02
bao kv put secret/lab/linux-03/labuser username=labuser password=demo-labuser-03
```

Questa PoC usa Teleport per accesso identity-based. Se il requisito futuro diventa "nessuna modifica ai nodi", il modello da valutare non e' l'agent Teleport sui nodi, ma OpenSSH CA, un bastion/gateway dedicato o un'integrazione custom.

## Script utili

```sh
docker compose exec teleport-auth /opt/teleport-lab/scripts/show-status.sh
docker compose exec teleport-auth /opt/teleport-lab/scripts/create-join-tokens.sh
```

## Applicazione A Un Lab Esistente

La procedura per replicare questo modello in un laboratorio gia presente e' in:

- `docs/existing-lab-tutorial.md`

Il documento parte da asset inventory, DNS/TLS, installazione Teleport Auth/Proxy/Agent, RBAC, nodo `vault-log`, rsyslog centrale e validazione end-to-end.

## Pulizia

```sh
docker compose down
docker compose down -v
```

`down -v` elimina anche lo stato Teleport e OpenBao.
