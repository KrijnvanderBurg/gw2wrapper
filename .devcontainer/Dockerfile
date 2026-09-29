# Devcontainer image: base + apko/melange (Wolfi image build tooling)
# Rust and Python/pipx are installed via devcontainer features, not here.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG APKO_VERSION=1.4.5
ARG MELANGE_VERSION=0.61.1

RUN mkdir -p /tmp/apko /tmp/melange && \
    curl -sSfL "https://github.com/chainguard-dev/apko/releases/download/v${APKO_VERSION}/apko_${APKO_VERSION}_linux_amd64.tar.gz" \
        | tar -xzf - -C /tmp/apko && \
    curl -sSfL "https://github.com/chainguard-dev/melange/releases/download/v${MELANGE_VERSION}/melange_${MELANGE_VERSION}_linux_amd64.tar.gz" \
        | tar -xzf - -C /tmp/melange && \
    find /tmp/apko -type f -name apko -exec mv {} /usr/local/bin/apko \; && \
    find /tmp/melange -type f -name melange -exec mv {} /usr/local/bin/melange \; && \
    chmod +x /usr/local/bin/apko /usr/local/bin/melange && \
    rm -rf /tmp/apko /tmp/melange
