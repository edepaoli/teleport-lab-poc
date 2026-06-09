# Limitazioni

- I certificati TLS dei proxy sono self-signed e adatti solo alla PoC locale.
- Il join token e' statico per semplificare l'avvio; in produzione usare token a TTL breve o join method piu robusti.
- OpenBao non e' integrato con Teleport in questa PoC.
- I nodi laboratorio contengono il Teleport agent. In scenari reali equivale a installare l'agent sui server.
- Fluent Bit e' usato solo come shipper locale verso il server rsyslog. La PoC non sostituisce una pipeline SIEM completa.
- Teleport 17 rifiuta `second_factor: off`; questa PoC mantiene MFA attivo. Per una demo password-only serve una variante con versione/configurazione compatibile.
