set shell := ["bash", "-euo", "pipefail", "-c"]

image := "gw2wrapper"
arch := arch()
docker_arch := if arch == "aarch64" { "arm64" } else { "amd64" }
tag := `git rev-parse --short=12 HEAD`
out := "build"
melange_key := out / "melange-" + arch + ".rsa"
apko_tar := out / image + "-" + arch + ".tar"

# Reproducible timestamps in melange packages and apko images
export SOURCE_DATE_EPOCH := `git log -1 --format=%ct`

# List available recipes
default:
    @just --list

# Cargo check (mirrors CI "Check, Test & Lint")
check:
    cargo check --locked --all-targets --all-features

# Run the test suite
test:
    cargo test --locked --all-targets --all-features

# Run Clippy; lint levels live in Cargo.toml [lints]
clippy:
    cargo clippy --locked --all-targets --all-features -- -D warnings

# Verify rustfmt formatting
fmt:
    cargo fmt --all -- --check

# Apply rustfmt formatting
fmt-fix:
    cargo fmt --all

# Build docs with rustdoc warnings as errors
doc:
    RUSTDOCFLAGS="-D warnings" cargo doc --locked --no-deps --document-private-items

# cargo-deny: advisories
deny-advisories:
    cargo deny --locked check advisories

# cargo-deny: licenses
deny-licenses:
    cargo deny --locked check licenses

# cargo-deny: bans, build scripts & sources
deny-bans:
    cargo deny --locked check bans sources

# Run all cargo-deny checks
deny: deny-advisories deny-licenses deny-bans

# Build the release binary with embedded dependency metadata (same command as melange.yaml)
build-release:
    cargo auditable build --locked --release

# Lint GitHub Actions workflows for security issues
zizmor:
    zizmor .github

# Lint GitHub Actions workflows for correctness
actionlint:
    actionlint

# Scan the git history for leaked secrets
gitleaks:
    gitleaks git --redact --no-banner

# Lint the devcontainer Dockerfile
hadolint:
    hadolint .devcontainer/Dockerfile

# Lint repository shell scripts
shellcheck:
    shellcheck .github/scripts/*.sh

# Verify justfile formatting
just-fmt:
    just --fmt --check --unstable

# Apply justfile formatting
just-fmt-fix:
    just --fmt --unstable

# Generate a local signing key for melange, if one doesn't already exist
melange-keygen:
    mkdir -p {{ out }}
    test -f {{ melange_key }} || melange keygen {{ melange_key }}

# Build the gw2wrapper apk package for the host arch with melange
melange-build: melange-keygen
    melange build melange.yaml --arch {{ arch }} --signing-key {{ melange_key }} --out-dir {{ out }}/packages --runner bubblewrap --license Apache-2.0

# Run the test pipeline from melange.yaml against the locally built package
melange-test: melange-build
    melange test melange.yaml --arch {{ arch }} --repository-append {{ justfile_directory() }}/{{ out }}/packages --keyring-append {{ melange_key }}.pub --runner bubblewrap

# Build the host-arch image tarball with the melange-built package
base: melange-build
    apko build apko.yaml {{ image }}:{{ tag }} {{ apko_tar }} --arch {{ arch }} -b {{ out }}/packages -k {{ melange_key }}.pub -p {{ image }} --sbom-path {{ out }}

# Assemble the multi-arch image from per-arch packages (CI "Multi-arch Image"; same inputs as publish-image.sh, without pushing)
image-multiarch:
    mkdir -p {{ out }}/sbom
    apko build apko.yaml {{ image }}:{{ tag }} {{ out }}/{{ image }}.tar -b {{ out }}/packages -k {{ out }}/melange-x86_64.rsa.pub -k {{ out }}/melange-aarch64.rsa.pub -p {{ image }} --sbom-path {{ out }}/sbom

# Scan the image tarball with two independent vulnerability databases
# CI overrides output via TRIVY_FORMAT/TRIVY_OUTPUT and GRYPE_OUTPUT (SARIF for code scanning)
scan:
    trivy image --config trivy.yaml --input {{ apko_tar }}
    grype --config .grype.yaml -o "${GRYPE_OUTPUT:-table}" docker-archive:{{ apko_tar }}

# Mirrors CI "Build & Container Verification": test the package, build the image, scan it
verify-image: melange-test base scan

# Run the image locally with production runtime hardening
run: base
    docker load -i {{ apko_tar }}
    docker run --rm --read-only --cap-drop=ALL --security-opt=no-new-privileges {{ image }}:{{ tag }}-{{ docker_arch }}

# Remove all melange/apko build outputs
clean:
    rm -rf {{ out }}
