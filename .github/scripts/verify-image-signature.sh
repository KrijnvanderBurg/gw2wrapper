#!/usr/bin/env bash
# Verifies that an image was signed, with SBOM attestation, by rust.yml on main, a version tag, or a same-repo PR (RC build).
set -euo pipefail

identity='^https://github\.com/KrijnvanderBurg/gw2wrapper/\.github/workflows/rust\.yml@refs/(heads/main|tags/v.+|pull/[0-9]+/merge)$'
issuer="https://token.actions.githubusercontent.com"

cosign verify --certificate-identity-regexp "$identity" --certificate-oidc-issuer "$issuer" "$1" > /dev/null
cosign verify-attestation --type spdxjson --certificate-identity-regexp "$identity" --certificate-oidc-issuer "$issuer" "$1" > /dev/null
echo "Verified signature and SBOM attestation of $1"
