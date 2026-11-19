ARG POSTGRES_VERSION=15
FROM debian:bookworm

ARG POSTGRES_VERSION
ENV PG_VERSION=${POSTGRES_VERSION} \
    PGDATA=/var/lib/postgresql/data \
    PATH=/usr/lib/postgresql/${POSTGRES_VERSION}/bin:$PATH

# Não criar o cluster "main" por omissão
RUN mkdir -p /etc/postgresql-common \
 && echo 'create_main_cluster = false' > /etc/postgresql-common/createcluster.conf \
 && apt-get update \
 && apt-get install -y --no-install-recommends postgresql-${POSTGRES_VERSION} gosu \
 && rm -rf /var/lib/apt/lists/*

COPY dir_config/postgresql.conf /etc/postgresql/postgresql.conf
COPY dir_script/script.sh /usr/local/bin/script.sh
RUN chown postgres:postgres /etc/postgresql/postgresql.conf \
 && chmod +x /usr/local/bin/script.sh

EXPOSE 5432
ENTRYPOINT ["/usr/local/bin/script.sh"]