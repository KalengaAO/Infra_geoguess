ARG POSTGRES_VERSION=15
FROM debian:bookworm
ARG POSTGRES_VERSION

RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-client-${POSTGRES_VERSION} tar gzip \
 && rm -rf /var/lib/apt/lists/*

COPY dir_script/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

ENTRYPOINT ["/usr/local/bin/script.sh"]
CMD ["daemon"]