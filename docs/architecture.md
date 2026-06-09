# Architettura

```mermaid
flowchart LR
    U["Utente browser/tsh"] --> PA["teleport-proxy-a :3080/:3023"]
    U --> PB["teleport-proxy-b :3180/:3123"]
    PA --> A["teleport-auth :3025"]
    PB --> A
    N1["lab-linux-01"] --> A
    N2["lab-linux-02"] --> A
    N3["lab-linux-03"] --> A
    NA["lab-admin-01"] --> A
    V["vault-log"] --> A
    A --> AUD["audit files"]
    PA --> LOG["proxy log files"]
    PB --> LOG
    N1 --> NLOG["node log files"]
    N2 --> NLOG
    N3 --> NLOG
    NA --> NLOG
    V --> NLOG
    AUD --> FB["fluent-bit shipper"]
    LOG --> FB
    NLOG --> FB
    FB --> RS["vault-log-rsyslog TCP/UDP 514"]
    RS --> RFILES["vault-log/logs/rsyslog"]
    OB["OpenBao"] -. futuro vaulting .- A
```

Teleport Auth e' l'unico componente che possiede lo storage cluster. I due proxy sono punti di accesso equivalenti allo stesso cluster e si registrano tramite token. I nodi laboratorio eseguono il Teleport node service e usano label per RBAC.

OpenBao non e' collegato automaticamente a Teleport: serve a mostrare dove potrebbero vivere segreti e password in una fase successiva.
