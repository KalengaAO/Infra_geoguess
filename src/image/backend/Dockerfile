FROM debian:bookworm

ARG GIT_REPO=https://github.com/KalengaAO/GeoguessAngola.git
ARG GIT_BRANCH=main

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    git ca-certificates python3 python3-pip python3-venv python3-dev gcc libpq-dev \
 && mkdir -p /app && rm -rf /var/lib/apt/lists/* \
 && python3 -m venv /opt/venv

WORKDIR /app

RUN git clone --depth 1 --branch ${GIT_BRANCH} --filter=blob:none --sparse ${GIT_REPO} /tmp/repo \
 && cd /tmp/repo && git sparse-checkout set backend \
 && cp -a backend/. /app/ \
 && rm -rf /tmp/repo

RUN pip install --no-cache-dir -r requirements.txt \
 && pip install --no-cache-dir gunicorn

COPY dir_script/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh \
 && useradd -m appuser && chown -R appuser:appuser /app

USER appuser
EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/script.sh"]