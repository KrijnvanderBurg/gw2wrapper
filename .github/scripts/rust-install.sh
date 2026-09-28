#!/bin/bash
set -euo pipefail

# apt-get update && apt-get install -y gnupg curl

# Minimal Secure Rust Installation (User-Local, Standalone Archive)

RUST_VERSION="1.82.0"
ARCH="x86_64-unknown-linux-gnu"
INSTALL_DIR="$HOME/.local/rust"
DOWNLOAD_DIR=$(mktemp -d)
trap "rm -rf $DOWNLOAD_DIR" EXIT

# 1. Download installer and signature
echo "Downloading Rust $RUST_VERSION..."
curl -fsSL "https://static.rust-lang.org/dist/rust-$RUST_VERSION-$ARCH.tar.gz" -o "$DOWNLOAD_DIR/rust.tar.gz"
curl -fsSL "https://static.rust-lang.org/dist/rust-$RUST_VERSION-$ARCH.tar.gz.asc" -o "$DOWNLOAD_DIR/rust.tar.gz.asc"

# 2. Import Rust signing key and verify signature
echo "Verifying GPG signature..."
curl -fsSL "https://static.rust-lang.org/rust-key.gpg.ascii" | gpg --import
gpg --verify "$DOWNLOAD_DIR/rust.tar.gz.asc" "$DOWNLOAD_DIR/rust.tar.gz"

# 3. Extract and install
mkdir -p "$INSTALL_DIR"
tar -xzf "$DOWNLOAD_DIR/rust.tar.gz" -C "$DOWNLOAD_DIR"
"$DOWNLOAD_DIR/rust-$RUST_VERSION-$ARCH/install.sh" --prefix="$INSTALL_DIR" --without=rust-docs

# 4. Setup PATH and verify
export PATH="$INSTALL_DIR/bin:$PATH"
echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" >> ~/.bashrc
rustc --version && cargo --version && echo "✓ Rust $RUST_VERSION installed successfully to $INSTALL_DIR"
