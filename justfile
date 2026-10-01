image := "gw2wrapper"
tag := "latest"
apko_tar := image + "-apko.tar"

# Build everything: melange package, then the apko image
build: base

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

# Generate a local signing key for melange, if one doesn't already exist
melange-keygen:
    test -f melange.rsa || melange keygen

# Build the hello-world apk package with melange, signed with the local key
melange-build: melange-keygen
    melange build melange.yaml --arch x86_64 --signing-key melange.rsa --runner bubblewrap

# Run the test pipeline from melange.yaml against the locally built package
melange-test: melange-build
    melange test melange.yaml --arch x86_64 --repository-append {{justfile_directory()}}/packages --keyring-append melange.rsa.pub --runner bubblewrap

# Build the apko image tarball (includes the melange-built application package)
base: melange-build
    apko build apko.yaml {{image}}:{{tag}} {{apko_tar}}

# Mirrors CI "Build & Container Verification": test the package, build the image, scan it with Trivy
verify-image: melange-test base
    docker load -i {{apko_tar}}
    trivy image --config trivy.yaml {{image}}:{{tag}}-amd64

# Remove generated apko tarball, melange packages and signing key
clean:
    rm -rf {{apko_tar}} packages melange.rsa melange.rsa.pub
