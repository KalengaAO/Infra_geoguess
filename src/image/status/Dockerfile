FROM debian:bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends tini python3 \
 && rm -rf /var/lib/apt/lists/*

COPY dir_config/status.py /opt/status/status.py
COPY dir_config/status.html /opt/status/status.html
COPY dir_script/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

USER nobody
EXPOSE 8081
ENTRYPOINT ["/usr/local/bin/script.sh"]