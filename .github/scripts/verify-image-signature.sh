#!/usr/bin/env bash
# Verifies that an image was signed, with SBOM attestation, by release.yml dispatched from main.
set -euo pipefail

identity='^https://github\.com/KrijnvanderBurg/gw2wrapper/\.github/workflows/release\.yml@refs/heads/main$'
issuer="https://token.actions.githubusercontent.com"

cosign verify --certificate-identity-regexp "$identity" --certificate-oidc-issuer "$issuer" "$1" > /dev/null
cosign verify-attestation --type spdxjson --certificate-identity-regexp "$identity" --certificate-oidc-issuer "$issuer" "$1" > /dev/null
echo "Verified signature and SBOM attestation of $1"
