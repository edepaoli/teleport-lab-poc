# Tutorial: Applicare Il Modello A Un Laboratorio Gia Presente

Questa procedura traduce la PoC Docker in un laboratorio reale o gia esistente. L'obiettivo e mantenere pochi asset chiari:

- control plane Teleport;
- uno o piu proxy/gateway;
- nodi laboratorio esistenti;
- un nodo centrale `vault-log` per consultazione log e vault;
- servizi interni come rsyslog, OpenBao e shipper log non esposti come ulteriori nodi SSH.

## 1. Censire Gli Asset

Prima di installare software, crea una tabella simile a questa:

| Asset | IP/FQDN | Funzione | Deve apparire in Teleport? | Login Linux ammessi |
|---|---|---|---|---|
| `teleport-auth` | `10.0.0.10` | Auth server | No | n/a |
| `teleport-proxy-a` | `10.0.0.11` | Gateway primario | No | n/a |
| `teleport-proxy-b` | `10.0.0.12` | Gateway secondario | No | n/a |
| `lab-linux-01` | `10.0.1.21` | Nodo lab | Si | `root`, `labuser` |
| `lab-linux-02` | `10.0.1.22` | Nodo lab | Si | `root`, `labuser`, `mario` |
| `lab-admin-01` | `10.0.1.30` | Nodo admin | Si | `root`, `admin`, `labuser` |
| `vault-log` | `10.0.2.10` | Vault/log access node | Si | `root`, `admin` |
| `rsyslog` | `10.0.2.11` | Log receiver | No | n/a |

Regola pratica: se un componente e' solo infrastruttura interna, non trasformarlo automaticamente in nodo Teleport.

## 2. Preparare DNS E TLS

In un laboratorio reale evita `localhost`:

- `teleport.example.lab` per il proxy primario;
- `teleport-b.example.lab` per il proxy secondario;
- certificati TLS validi per i proxy, anche emessi da CA interna;
- NTP o clock sync funzionante, indispensabile per TOTP/MFA.

Per WebAuthn/YubiKey, `rp_id` deve corrispondere al dominio reale usato dagli utenti.

## 3. Installare Teleport Auth

Sul server scelto come Auth:

1. installa Teleport Community Edition;
2. configura `auth_service` abilitato;
3. disabilita `proxy_service` e `ssh_service`;
4. usa storage persistente;
5. configura audit events e session recordings su filesystem o backend supportato;
6. abilita MFA secondo policy.

Esempio concettuale:

```yaml
auth_service:
  enabled: "yes"
  cluster_name: teleport-lab.local
  authentication:
    type: local
    second_factor: on
    webauthn:
      rp_id: teleport.example.lab

ssh_service:
  enabled: "no"

proxy_service:
  enabled: "no"
```

## 4. Installare I Proxy/Gateway

Su ogni gateway:

1. installa Teleport;
2. configura `proxy_service` abilitato;
3. disabilita `auth_service` e `ssh_service`;
4. registra il proxy usando token a TTL breve;
5. pubblica Web UI, SSH proxy e reverse tunnel.

Mantieni almeno due proxy solo se serve davvero dimostrare alta disponibilita o accessi multipli.

## 5. Enrollare I Nodi Laboratorio

Su ogni nodo laboratorio esistente:

1. crea o verifica gli utenti Linux richiesti, ad esempio `root`, `admin`, `labuser`, `mario`;
2. installa Teleport agent;
3. configura solo `ssh_service`;
4. assegna label coerenti.

Esempio:

```yaml
teleport:
  nodename: lab-linux-02
  auth_server: teleport-auth.example.lab:3025
  auth_token: <token-temporaneo>

auth_service:
  enabled: "no"

proxy_service:
  enabled: "no"

ssh_service:
  enabled: "yes"
  labels:
    env: lab
    os: linux
    criticality: medium
    group: standard
```

Verifica:

```sh
tctl nodes ls
tsh ls
```

## 6. Configurare Ruoli RBAC

Esempio policy:

- `lab-user`: accesso ai nodi standard, login Linux limitati;
- `lab-admin`: accesso a tutti i nodi `env=lab`, incluso `vault-log`.

Esempi di test:

```sh
tsh ssh labuser@lab-linux-02
tsh ssh mario@lab-linux-02
tsh ssh root@lab-linux-02
tsh ssh root@vault-log
```

Dopo modifiche ai ruoli, gli utenti devono rifare login:

```sh
tsh logout
tsh login --proxy=teleport.example.lab --user=mario.rossi
```

## 7. Preparare Il Nodo Vault/Log

Il nodo `vault-log` deve essere l'unico punto operativo per:

- consultare i log centralizzati;
- amministrare o raggiungere OpenBao;
- validare audit e session recordings.

Sul nodo `vault-log` monta o rendi disponibile:

```text
/vault-log/logs/
/vault-log/logs/rsyslog/all.log
/vault-log/logs/rsyslog/by-host/
```

In produzione puoi usare filesystem locale, NFS interno, volume dedicato o storage approvato dal laboratorio.

## 8. Configurare Rsyslog Centrale

Il server rsyslog riceve log da nodi, Teleport e shipper:

- TCP/UDP 514 sulla rete interna;
- file aggregato `all.log`;
- file separati per host.

Esempio rsyslog:

```conf
module(load="imtcp")
module(load="imudp")

input(type="imtcp" port="514")
input(type="imudp" port="514")

template(
  name="RemoteByHost"
  type="string"
  string="/var/log/remote/by-host/%HOSTNAME%.log"
)

template(
  name="RemoteLine"
  type="string"
  string="%timegenerated% %HOSTNAME% %syslogtag%%msg%\n"
)

*.* action(type="omfile" file="/var/log/remote/all.log" template="RemoteLine")
*.* action(type="omfile" dynaFile="RemoteByHost" template="RemoteLine")
```

## 9. Inoltrare Log E Audit

Sorgenti minime:

- Teleport Auth log;
- Teleport Proxy log;
- Teleport audit events;
- log dei nodi laboratorio;
- log del nodo `vault-log`.

Puoi usare Fluent Bit, rsyslog client o agent SIEM gia presente. In un ambiente esistente evita di introdurre due agent se ne esiste gia uno approvato.

## 10. Validare End-To-End

Checklist:

```sh
tctl status
tctl users ls
tctl nodes ls
tsh login --proxy=teleport.example.lab --user=mario.rossi
tsh ls
tsh ssh labuser@lab-linux-02
tsh ssh root@vault-log
tail -f /vault-log/logs/rsyslog/all.log
```

Genera un evento controllato:

```sh
logger -n <rsyslog-ip> -P 514 -T "lab-linux-02 test syslog"
```

Poi verifica:

```sh
grep "lab-linux-02 test syslog" /vault-log/logs/rsyslog/all.log
```

## 11. Errori Da Evitare

- Non trasformare ogni servizio Docker o processo interno in nodo Teleport.
- Non usare token statici in un ambiente reale.
- Non lasciare certificati self-signed se il lab deve testare WebAuthn in modo realistico.
- Non usare OpenBao come log store: OpenBao serve ai segreti, rsyslog/SIEM ai log.
- Non confondere il nodo `vault-log` con il servizio rsyslog: `vault-log` e' il punto operativo, rsyslog e' un servizio dietro di esso.
