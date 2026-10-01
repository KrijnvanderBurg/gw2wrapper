#!/usr/bin/env bash
# Publishes the multi-arch image from the melange packages in build/, then keyless-signs it and attests its SBOMs.
#
# Tags produced, by trigger:
#   - version tag (refs/tags/vX.Y.Z): X.Y.Z, X.Y, X, latest, sha-<short>
#   - main branch:                    edge, sha-<short>
#   - manual dispatch (RC):           <version>-rc.sha-<short>, sha-<short>
set -euo pipefail

sha="$(git rev-parse --short=12 HEAD)"
tags=("sha-${sha}")

if [[ "$GITHUB_REF" == refs/tags/v* ]]; then
    version="${GITHUB_REF_NAME#v}"
    tags+=("$version" "${version%.*}" "${version%%.*}" "latest")
    primary_tag="$version"
elif [[ "$GITHUB_REF" == "refs/heads/main" ]]; then
    tags+=("edge")
    primary_tag="edge"
else
    version="$(grep -m1 '^version = ' Cargo.toml | cut -d'"' -f2)"
    tags+=("${version}-rc.sha-${sha}")
    primary_tag="${version}-rc.sha-${sha}"
fi

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
