FROM ubuntu:24.04
RUN apt-get update \
    && apt-get install -y --no-install-recommends rsyslog ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/log/remote
COPY rsyslog.conf /etc/rsyslog.conf
EXPOSE 514/tcp 514/udp
CMD ["rsyslogd", "-n", "-f", "/etc/rsyslog.conf"]
