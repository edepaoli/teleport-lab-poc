ARG TELEPORT_VERSION=17.7.0
FROM public.ecr.aws/gravitational/teleport-distroless-debug:${TELEPORT_VERSION} AS teleport

FROM ubuntu:24.04
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates bash sudo \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash labuser \
    && useradd -m -s /bin/bash admin \
    && echo 'root:teleport-lab' | chpasswd \
    && echo 'labuser:teleport-lab' | chpasswd \
    && echo 'admin:teleport-lab' | chpasswd \
    && usermod -aG sudo admin
COPY --from=teleport /usr/local/bin/teleport /usr/local/bin/tctl /usr/local/bin/tsh /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
