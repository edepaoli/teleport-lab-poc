ARG TELEPORT_VERSION=17.7.0
FROM public.ecr.aws/gravitational/teleport-distroless-debug:${TELEPORT_VERSION} AS teleport

FROM ubuntu:24.04
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates bash \
    && rm -rf /var/lib/apt/lists/*
COPY --from=teleport /usr/local/bin/teleport /usr/local/bin/tctl /usr/local/bin/tsh /usr/local/bin/
ENTRYPOINT []
