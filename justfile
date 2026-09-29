image := "gw2wrapper"
tag := "latest"
apko_tar := image + "-apko.tar"

# Build everything: apko base image, then the docker image
build: docker

# Cargo check (mirrors CI "Check, Test & Lint")
check:
    cargo check --all-targets

# Run the test suite
test:
    cargo test --all-targets

# Run Clippy to catch common mistakes
clippy:
    cargo clippy --all-targets -- -D warnings

# Verify rustfmt formatting
fmt:
    cargo fmt --all -- --check

# cargo-deny: advisories
deny-advisories:
    cargo deny check advisories

# cargo-deny: licenses
deny-licenses:
    cargo deny check licenses

# cargo-deny: bans & sources
deny-bans:
    cargo deny check bans sources

# Run all cargo-deny checks
deny: deny-advisories deny-licenses deny-bans

# Build the release binary with embedded dependency metadata
build-release:
    cargo auditable build --locked --release

# Smoke test that the wolfi/apko image still builds
apko-smoke:
    apko build apko.yaml {{image}}:test ./{{apko_tar}}

# Build and load the apko base image (dependency for docker build)
base:
    apko build apko.yaml {{image}}:{{tag}} {{apko_tar}}
    docker load < {{apko_tar}}

# Build the application image on top of the apko base image
docker: base
    docker build -t {{image}}-app:{{tag}} .

# Remove generated apko tarball
clean:
    rm -f {{apko_tar}}
