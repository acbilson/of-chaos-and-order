FROM debian:trixie-slim

ARG HUGO_VERSION=0.152.2
ARG TARGETARCH

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    tar \
  && rm -rf /var/lib/apt/lists/*

RUN case "$TARGETARCH" in \
      amd64) HUGO_ARCH="linux-amd64" ;; \
      arm64) HUGO_ARCH="linux-arm64" ;; \
      *) echo "Unsupported architecture: $TARGETARCH" && exit 1 ;; \
    esac \
  && curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_${HUGO_ARCH}.tar.gz" -o /tmp/hugo.tar.gz \
  && tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin hugo \
  && rm /tmp/hugo.tar.gz \
  && hugo version

# adds theme, content and config
RUN mkdir -p /app/hugo
COPY ./content /app/hugo
WORKDIR /app/hugo

RUN mkdir -p /app/themes
COPY ./themes /app/themes

RUN mkdir -p /etc/hugo
COPY ./build/config.toml /etc/hugo/config.toml

WORKDIR /app

EXPOSE 6300

CMD ["hugo", "server", "--source", "/app/hugo", "--config", "/etc/hugo/config.toml", "--themesDir", "/app/themes", "--bind", "0.0.0.0", "--port", "6300", "--appendPort=false"]
