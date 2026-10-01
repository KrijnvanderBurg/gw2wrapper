# Devcontainer image: base + mise (installs the tools pinned in mise.toml)
# Rust and Python are installed via devcontainer features, not here.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG MISE_VERSION=2026.9.18
ARG MISE_SHA256=d24fe0bf7e613824ad99f7b8dac3f2b381a37b9f75f84dd250855217095a8de4

# bubblewrap is required by melange to run its build sandbox
RUN apt-get update && \
    apt-get install -y --no-install-recommends bubblewrap && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sSfLo /usr/local/bin/mise \
        "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-x64" && \
    echo "${MISE_SHA256}  /usr/local/bin/mise" | sha256sum -c - && \
    chmod 0755 /usr/local/bin/mise
