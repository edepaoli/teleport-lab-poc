# Asset Inventory

Questa inventory definisce la baseline desiderata della PoC. Gli asset sono divisi tra nodi accessibili via Teleport e componenti di servizio. I componenti di servizio non devono essere trattati come ulteriori nodi laboratorio.

## Scope

Cluster locale Docker Compose per demo Teleport Community Edition con:

- accesso centralizzato via Teleport;
- pochi nodi laboratorio;
- un nodo centrale per vault e log;
- componenti di supporto per vaulting e logging.

## Nodi Accessibili Via Teleport

| Asset | Tipo | Ruolo | Accesso Teleport | Label principali | Note |
|---|---|---|---|---|---|
| `teleport-auth` | Teleport Auth Server | Control plane Teleport | No SSH lab | n/a | Gestisce identita, ruoli, audit, join token e CA del cluster. |
| `teleport-proxy-a` | Teleport Proxy/Gateway | Gateway primario | No SSH lab | n/a | Espone Web UI e accesso `tsh` su `https://localhost:3080`. |
| `teleport-proxy-b` | Teleport Proxy/Gateway | Gateway secondario | No SSH lab | n/a | Espone Web UI e accesso `tsh` su `https://localhost:3180`. |
| `lab-linux-01` | Nodo laboratorio Linux | Nodo standard | Si | `env=lab`, `group=standard`, `criticality=low` | Nodo demo per accesso utente standard. |
| `lab-linux-02` | Nodo laboratorio Linux | Nodo standard | Si | `env=lab`, `group=standard`, `criticality=medium` | Nodo demo con utente Linux aggiuntivo `mario`. |
| `lab-linux-03` | Nodo laboratorio Linux | Nodo standard | Si | `env=lab`, `group=standard`, `criticality=high` | Nodo demo standard ad alta criticita. |
| `lab-admin-01` | Nodo laboratorio Linux | Nodo amministrativo | Si | `env=lab`, `group=admin`, `criticality=high` | Nodo amministrativo, accessibile al ruolo `lab-admin`. |
| `vault-log` | Nodo centrale Linux | Vault e log access node | Si | `env=lab`, `group=vault`, `service=vault-log` | Nodo unico da usare per consultare log e componente vault/log. |

## Componenti Di Servizio

Questi componenti fanno parte della piattaforma, ma non dovrebbero aumentare il numero di host laboratorio visibili all'utente finale.

| Componente | Tipo | Esposto su host | Accesso Teleport | Funzione |
|---|---|---:|---|---|
| `openbao` / `vault-log-openbao` | OpenBao | `localhost:8200` | No | Vault segreti demo/futuro password vaulting. |
| `vault-log-rsyslog` | rsyslog server | `localhost:5514` TCP/UDP | No, service-only | Riceve log via syslog e scrive in `vault-log/logs/rsyslog`. |
| `fluent-bit` / `vault-log-fluent-bit` | Log shipper | No | No | Legge file log e audit, poi inoltra a rsyslog. |
| Docker volumes Teleport | Storage persistente | No | No | Stato Auth/Proxy e dati cluster. |

## Flusso Logging

```text
Teleport Auth logs
Teleport Proxy logs
Teleport audit events
Node logs
        |
        v
Fluent Bit
        |
        v
rsyslog service
        |
        v
vault-log/logs/rsyslog/all.log
vault-log/logs/rsyslog/by-host/<host>.log
```

Dal nodo `vault-log`, i log devono essere consultabili in:

```text
/vault-log/logs/
/vault-log/logs/rsyslog/all.log
/vault-log/logs/rsyslog/by-host/
```

## Utenti Teleport

| Utente Teleport | Ruolo | Scope atteso |
|---|---|---|
| `mario.rossi` | `lab-user` | Accesso ai nodi standard autorizzati, in particolare `lab-linux-01` e `lab-linux-02`. |
| `admin.lab` | `lab-admin` | Accesso amministrativo a tutti i nodi `env=lab`, incluso `vault-log`. |

## Login Linux Attesi

| Nodo | Login Linux attesi |
|---|---|
| `lab-linux-01` | `root`, `admin`, `labuser` |
| `lab-linux-02` | `root`, `admin`, `labuser`, `mario` |
| `lab-linux-03` | `root`, `admin`, `labuser` |
| `lab-admin-01` | `root`, `admin`, `labuser` |
| `vault-log` | `root`, `admin`, `labuser`, `mario` |

## Regola Di Controllo

La lista nodi Teleport desiderata non deve crescere oltre questi host:

```text
lab-linux-01
lab-linux-02
lab-linux-03
lab-admin-01
vault-log
```

`teleport-auth`, `teleport-proxy-a` e `teleport-proxy-b` sono componenti Teleport, non nodi laboratorio SSH.

`openbao`, `vault-log-rsyslog` e `fluent-bit` sono componenti di servizio e non devono apparire come nodi laboratorio accessibili via Teleport.

## Nota Di Riallineamento

Se `vault-log-rsyslog` appare in `tsh ls`, va trattato come errore di modellazione della PoC: il servizio rsyslog deve restare dietro al nodo `vault-log`, non diventare un ulteriore asset SSH. Il punto operativo per l'utente deve rimanere `vault-log`.
