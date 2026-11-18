
FROM debian:bookworm

LABEL maintainer="GeoGuess Angola"
LABEL description="PostgreSQL 15.19 custom image for GeoGuess Angola"

ENV PG_MAJOR=15
ENV PGDATA=/var/lib/postgresql/data
ENV PG_CONFIG_FILE=/etc/postgresql/postgresql.conf
ENV PATH="/usr/lib/postgresql/15/bin:${PATH}"

# Instalar dependências necessárias
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        gosu \
        postgresql-common \
    && sed -i 's/^#\?create_main_cluster.*/create_main_cluster = false/' \
        /etc/postgresql-common/createcluster.conf \
    && apt-get install -y --no-install-recommends \
        postgresql-15=15.19-0+deb12u1 \
    && rm -rf /var/lib/apt/lists/*

# Criar o directório de dados
RUN mkdir -p "${PGDATA}" \
    && chown -R postgres:postgres /var/lib/postgresql

# Copiar os ficheiros de configuração e inicialização
COPY dir_config/postgresql.conf ${PG_CONFIG_FILE}
COPY dir_script/script.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh

# PostgreSQL escuta na porta interna 5432
EXPOSE 5432

STOPSIGNAL SIGINT

ENTRYPOINT ["/usr/local/bin/script.sh"]

CMD ["postgres"]
