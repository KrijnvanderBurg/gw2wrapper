#!/usr/bin/env bash
# Publishes the multi-arch image from the melange packages in build/, then keyless-signs it and attests its SBOMs.
# The version comes from Cargo.toml; release.yml guarantees it is not already released.
# Tags produced: X.Y.Z, X.Y, X, latest, sha-<short>
set -euo pipefail

version="$(grep -m1 '^version = ' Cargo.toml | cut -d'"' -f2)"
sha="$(git rev-parse --short=12 HEAD)"
tags=("$version" "${version%.*}" "${version%%.*}" "latest" "sha-${sha}")
primary_tag="$version"

refs=()
for tag in "${tags[@]}"; do
    refs+=("${IMAGE}:${tag}")
done

SOURCE_DATE_EPOCH="$(git log -1 --format=%ct)"
export SOURCE_DATE_EPOCH

# Static annotations live in apko.yaml; these vary per build so are passed on the CLI
annotations=(
    "org.opencontainers.image.revision:$(git rev-parse HEAD)"
    "org.opencontainers.image.created:$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%dT%H:%M:%SZ)"
    "org.opencontainers.image.version:${primary_tag}"
)

mkdir -p build/sbom
apko publish apko.yaml "${refs[@]}" \
    -b build/packages \
    -k build/melange-x86_64.rsa.pub \
    -k build/melange-aarch64.rsa.pub \
    -p gw2wrapper \
    --annotations "${annotations[0]}" --annotations "${annotations[1]}" --annotations "${annotations[2]}" \
    --sbom-path build/sbom \
    --image-refs build/image-refs

# Last line of image-refs is the multi-arch index
index="$(tail -1 build/image-refs)"
cosign sign --yes --recursive "$index"
cosign attest --yes --type spdxjson --predicate build/sbom/sbom-index.spdx.json "$index"

for arch in x86_64 aarch64; do
    sbom="build/sbom/sbom-${arch}.spdx.json"
    digest="$(jq -r '.packages[] | select(.SPDXID | startswith("SPDXRef-Package-Image-sha256-")) | .name' "$sbom")"
    cosign attest --yes --type spdxjson --predicate "$sbom" "${IMAGE}@${digest}"
done

echo "digest=${index#*@}" >> "$GITHUB_OUTPUT"
