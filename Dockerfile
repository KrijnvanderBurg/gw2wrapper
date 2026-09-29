# Multi-stage build for gw2wrapper
# Stage 1: Builder - Rust build with cargo-auditable
# Stage 2: Runtime - the wolfi-based image produced by apko.yaml (this repo's own image)
#
# Prerequisite: build and load the apko base image before running `docker build`:
#   apko build apko.yaml gw2wrapper:latest gw2wrapper-apko.tar
#   docker load < gw2wrapper-apko.tar

###############################################################################
# STAGE 1: Builder
# Builds static Rust binary with embedded dependency metadata via cargo-auditable
###############################################################################
FROM rust:latest as builder

# Install cargo-auditable
RUN cargo install cargo-auditable

WORKDIR /build

# Copy manifest files
COPY Cargo.toml Cargo.lock ./

# Copy source
COPY src ./src

# cargo-auditable wraps cargo build and embeds dependency info into binary
RUN cargo auditable build \
    --locked \
    --release

# Extract binary
RUN cp /build/target/release/hello-world /app

###############################################################################
# STAGE 2: Runtime
# gw2wrapper:latest - our own apko-built wolfi image (ca-certs + nonroot user only,
# no shell, no package manager). Must be loaded locally beforehand, see header.
###############################################################################
FROM gw2wrapper:latest

# Copy application binary from builder stage, owned by and readable only by appuser
COPY --from=builder --chown=appuser:appuser --chmod=0500 /app /usr/local/bin/hello-world

# Base image already defaults to this, set explicitly for clarity/defense-in-depth
USER appuser:appuser

# Set entrypoint (no shell invocation possible - image has no shell)
ENTRYPOINT ["/usr/local/bin/hello-world"]

# Labels for image metadata and provenance
LABEL org.opencontainers.image.title="gw2wrapper"
LABEL org.opencontainers.image.description="GW2 Wrapper - Minimal secure Rust application"
LABEL org.opencontainers.image.source="https://github.com/your-org/gw2wrapper"
