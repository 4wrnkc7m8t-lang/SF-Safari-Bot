# Webový panel pro iPhone Safari + veřejný Mercy SF CLI engine.
# Safari ovládá proces v cloudu, samotný iPhone engine nespouští.
FROM node:22-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl coreutils gosu \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY app.tar.gz /tmp/app.tar.gz
RUN tar -xzf /tmp/app.tar.gz -C /app && rm /tmp/app.tar.gz
# Stáhni pouze oficiální Mercy CLI a ověř jeho SHA256 proti manifestu vydavatele.
RUN mkdir -p /opt/mercy && \
    curl -fsSL --retry 3 https://mercysf.app/downloads/mercy-cli-linux-x64 -o /opt/mercy/mercy-cli-linux-x64 && \
    curl -fsSL --retry 3 https://mercysf.app/downloads/SHA256SUMS.txt -o /opt/mercy/SHA256SUMS.txt && \
    cd /opt/mercy && \
    sha256sum -c SHA256SUMS.txt --ignore-missing | grep -Fx 'mercy-cli-linux-x64: OK' && \
    chmod 755 /opt/mercy/mercy-cli-linux-x64
# Konfigurace enginu i šifrovaný účet jsou na trvalém disku Railway.
RUN mkdir -p /app/data && chown node:node /app/data
ENV HOST=0.0.0.0 ALLOW_REMOTE_BIND=1 TRUST_PROXY=1 \
    MERCY_CLI=/opt/mercy/mercy-cli-linux-x64 HOME=/app/data/home \
    XDG_CONFIG_HOME=/app/data/config XDG_DATA_HOME=/app/data/local/share XDG_CACHE_HOME=/app/data/cache \
    DATA_DIR=/app/data PORT=8080
EXPOSE 8080
# Svazek Railway připojuje s vlastníkem root; oprav ho a aplikaci spusť jako node.
CMD ["sh","-ec","mkdir -p /app/data/home /app/data/config /app/data/local/share /app/data/cache && chown -R node:node /app/data && exec gosu node node /app/server.js"]
