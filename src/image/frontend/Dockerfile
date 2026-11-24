FROM debian:bookworm

ARG GIT_REPO=https://github.com/KalengaAO/GeoguessAngola.git
ARG GIT_BRANCH=main
ARG NODE_MAJOR=22

RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl tini ca-certificates gnupg \
 && curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

 WORKDIR /app

RUN git clone --depth 1 --branch ${GIT_BRANCH} --filter=blob:none --sparse ${GIT_REPO} /tmp/repo \
 && cd /tmp/repo && git sparse-checkout set frontend \
 && cp -a frontend/. /app/ \
 && rm -rf /tmp/repo

RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY dir_script/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

EXPOSE 5173
ENTRYPOINT ["/usr/local/bin/script.sh"]