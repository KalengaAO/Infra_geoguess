FROM debian:bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx curl openssl \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /etc/nginx/ssl

COPY dir_config/nginx.conf /etc/nginx/nginx.conf
COPY dir_script/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

EXPOSE 443
ENTRYPOINT ["/usr/local/bin/script.sh"]