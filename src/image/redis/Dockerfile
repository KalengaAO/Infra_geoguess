FROM debian:bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends redis-server gosu \
 && rm -rf /var/lib/apt/lists/*

COPY dir_script/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

EXPOSE 6379
ENTRYPOINT ["/usr/local/bin/script.sh"]