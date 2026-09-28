# Secure Rust Installation: Security Rationale & Troubleshooting

## Security Verification Steps Explained

### 1. **Official Download Only**
- **Why**: Prevents MITM attacks and distribution tampering
- **Verification**: Uses `https://static.rust-lang.org/dist/` (official Rust infrastructure only)

### 2. **GPG Signature Verification**
- **Why**: Cryptographically proves the installer comes from the Rust Project
- **Process**:
  - Fetches Rust's public key (E1DD270017412F18)
  - Verifies `.asc` signature against the tarball
  - Aborts if verification fails (`exit 1`)

### 3. **User-Local Installation** (`~/.local/rust`)
- **Why**: No sudo required; doesn't modify system files; safe for air-gapped environments
- **Security benefit**: Isolated from system Rust; easy to remove or version-lock

### 4. **Tarball Extraction (No Pipe to Shell)**
- **Why**: Avoids `curl | sh` attack surface
- **Verification**: Downloaded archive is GPG-signed **before** extraction

### 5. **PATH Management**
- **Why**: Ensures local Rust is used, not conflicting system versions

---

## Troubleshooting GPG Verification Failures

### Error: "gpg: Can't check signature: No public key"
```bash
# Manually import Rust key
gpg --keyserver keyserver.ubuntu.com --recv-keys E1DD270017412F18

# Verify key fingerprint (get from https://forge.rust-lang.org/infra/signing-docs-and-keys.html)
gpg --list-key E1DD270017412F18
```
**Expected fingerprint:** `85AB15AD1551282F94817B23C8D77957A314B012`

### Error: "Bad signature from unknown key"
- The signing key has changed or is compromised
- Check official Rust documentation: https://forge.rust-lang.org/infra/signing-docs-and-keys.html
- Do NOT proceed with installation

### Error: "No such file or directory" during extraction
- The download failed silently; re-run with verbose curl: `curl -v ...`
- Check disk space: `df -h /tmp`

### Error: "install.sh: Permission denied"
- Make script executable: `chmod +x install-rust-secure.sh`

---

## Installation Manifest (After Successful Install)

To document the installation:

```bash
echo "=== Rust Installation Manifest ===" > rust-install-manifest.txt
echo "Version: $RUST_VERSION" >> rust-install-manifest.txt
echo "Install Date: $(date)" >> rust-install-manifest.txt
echo "Install Path: $INSTALL_DIR" >> rust-install-manifest.txt
echo "SHA-256 (rustc): $(sha256sum $INSTALL_DIR/bin/rustc)" >> rust-install-manifest.txt
echo "SHA-256 (cargo): $(sha256sum $INSTALL_DIR/bin/cargo)" >> rust-install-manifest.txt
rustc --version --verbose >> rust-install-manifest.txt
cargo --version >> rust-install-manifest.txt
```

---

## Version Pinning

To change Rust version, edit the script:
```bash
RUST_VERSION="1.81.0"  # Change this number
```

Available versions: https://static.rust-lang.org/dist/

---

## Air-Gapped Installation

After downloading on a connected system, transfer these files:
- `rust-$VERSION-$ARCH.tar.gz`
- `rust-$VERSION-$ARCH.tar.gz.asc`

Then run the script on the offline machine (GPG key must be imported separately or provided).

---

## Verification Steps Checklist

- [ ] Downloaded from `static.rust-lang.org` (HTTPS only)
- [ ] `.asc` signature file downloaded and verified
- [ ] GPG key fingerprint matches official documentation
- [ ] `rustc --version` and `cargo --version` work
- [ ] No system package manager involved (no apt/dnf/brew)
- [ ] No rustup installed
- [ ] Installation in `~/.local/rust` (user-local, not system-wide)
- [ ] PATH updated in `~/.bashrc`
