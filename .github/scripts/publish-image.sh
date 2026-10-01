#!/usr/bin/env bash
# Publishes the multi-arch image from the melange packages in build/, then keyless-signs it and attests its SBOMs.
set -euo pipefail

refs=("${IMAGE}:$(git rev-parse --short=12 HEAD)")
if [[ "$GITHUB_REF" == refs/tags/v* ]]; then
    refs+=("${IMAGE}:${GITHUB_REF_NAME#v}")
elif [[ "$GITHUB_REF" =~ ^refs/pull/([0-9]+)/merge$ ]]; then
    version="$(grep -m1 '^version = ' Cargo.toml | cut -d'"' -f2)"
    refs+=("${IMAGE}:${version}-rc.pr${BASH_REMATCH[1]}")
else
    refs+=("${IMAGE}:latest")
fi

SOURCE_DATE_EPOCH="$(git log -1 --format=%ct)"
export SOURCE_DATE_EPOCH

mkdir -p build/sbom
apko publish apko.yaml "${refs[@]}" \
    -b build/packages \
    -k build/melange-x86_64.rsa.pub \
    -k build/melange-aarch64.rsa.pub \
    -p gw2wrapper \
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
