FROM debian:bookworm

ARG ADMINER_VERSION=4.8.1

RUN apt-get update \
 && apt-get install -y --no-install-recommends php-cli php-pgsql ca-certificates curl \
 && mkdir -p /var/www/html \
 && curl -fsSL -o /var/www/html/index.php \
      https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php \
 && apt-get purge -y curl && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -r -s /usr/sbin/nologin adminer \
 && chown -R adminer:adminer /var/www/html

COPY dir_script/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

USER adminer

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/script.sh"]