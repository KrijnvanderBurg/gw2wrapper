# Multi-stage build for gw2wrapper
# Stage 1: Builder - Rust musl static build with cargo-auditable
# Stage 2: Runtime - Wolfi-based minimal image with explicit dependencies

###############################################################################
# STAGE 1: Builder
# Builds static Rust binary with embedded dependency metadata via cargo-auditable
###############################################################################
FROM rust:latest as builder

# Install musl target and cargo-auditable
RUN rustup target add x86_64-unknown-linux-musl && \
    cargo install cargo-auditable

WORKDIR /build

# Copy manifest files
COPY Cargo.toml Cargo.lock ./

# Copy source
COPY src ./src

# Build static binary with musl target
# cargo-auditable wraps cargo build and embeds dependency info into binary
RUN cargo-auditable build \
    --locked \
    --release \
    --target x86_64-unknown-linux-musl

# Extract binary
RUN cp /build/target/x86_64-unknown-linux-musl/release/hello-world /app

###############################################################################
# STAGE 2: Runtime
# Minimal Wolfi-based image with:
# - Non-root user (65532:65532)
# - CA certificates for HTTPS
# - Read-only root filesystem support
# - No shell, debugger, or package manager
###############################################################################
FROM cgr.dev/chainguard/wolfi-base:latest

# Install only essential runtime packages
# ca-certificates: Required for HTTPS verification
RUN apk add --no-cache ca-certificates-bundle

# Create explicit non-root application user (nomad UID convention)
RUN groupadd -g 65532 appuser && \
    useradd -u 65532 -g 65532 -s /sbin/nologin -d /nonexistent appuser

# Create minimal /tmp directory
RUN mkdir -p /tmp && chmod 1777 /tmp

# Copy application binary from builder stage
# Use explicit ownership: read-only by app user
COPY --from=builder --chown=appuser:appuser --chmod=0555 /app /usr/local/bin/hello-world

# Switch to non-root user
USER appuser

# Set entrypoint (no shell invocation needed)
ENTRYPOINT ["/usr/local/bin/hello-world"]

# Labels for image metadata and provenance
LABEL org.opencontainers.image.title="gw2wrapper"
LABEL org.opencontainers.image.description="GW2 Wrapper - Minimal secure Rust application"
LABEL org.opencontainers.image.source="https://github.com/your-org/gw2wrapper"
