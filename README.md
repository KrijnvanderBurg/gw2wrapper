# gw2wrapper

Minimal, secure Guild Wars 2 API wrapper, shipped as a distroless [Wolfi](https://wolfi.dev) container built with
[melange](https://github.com/chainguard-dev/melange) and [apko](https://github.com/chainguard-dev/apko).

## Development

Open the repo in appla the devcontainer. Tool versions are pinned in [mise.toml](mise.toml) (checksums in `mise.lock`) and
the Rust toolchain in [rust-toolchain.toml](rust-toolchain.toml), identical for devcontainer, pre-commit and CI.

Every check is a [just](https://github.com/casey/just) recipe, run by both pre-commit and CI:

| Command | Purpose |
| --- | --- |
| `just check test clippy fmt doc` | Build, test and lint (lint levels in `Cargo.toml` `[lints]`) |
| `just deny vet` | Advisories, licenses, bans, build scripts, sources and cargo-vet audits |
| `just zizmor actionlint gitleaks typos hadolint just-fmt` | Repository linters |
| `just verify-image` | Build and test the melange package, build the apko image, scan with Trivy and Grype |
| `just run` | Run the image with a read-only root filesystem, no capabilities and `no-new-privileges` |

`verify-image` runs on `pre-push`; everything else on `pre-commit`.

## CI/CD

- [rust.yml](.github/workflows/rust.yml): checks, audits, repository lint and a native x86_64/aarch64 image build and
  scan. On `main` and `v*` tags the multi-arch image is pushed to GHCR, keyless-signed with cosign, and gets SBOM and
  SLSA provenance attestations.
- [maintenance.yml](.github/workflows/maintenance.yml): weekly signature check and re-scan of the published image.
- [codeql.yml](.github/workflows/codeql.yml), [scorecard.yml](.github/workflows/scorecard.yml): CodeQL (Rust, Actions)
  and OpenSSF Scorecard.
- [Renovate](renovate.json) updates all pins. After a mise tool bump run `mise lock`; after a mise or Rust bump update
  `MISE_SHA256` in the devcontainer Dockerfile and the `rust-X.Y~X.Y.Z` pin in `melange.yaml` by hand.

## Repository settings (manual)

- Ruleset on `main`: require pull requests, signed commits and the CI status checks; block force pushes and deletions.
- Enable private vulnerability reporting, and allow GitHub Actions to create pull requests.
- Create a `release` environment (optionally with required reviewers) for the publish job.

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities and verifying images.

# Security Policy

## Reporting a vulnerability

Please do not open public issues for security problems. Report them privately through
[GitHub private vulnerability reporting](https://github.com/KrijnvanderBurg/gw2wrapper/security/advisories/new).
You can expect an acknowledgement within 7 days.

## Supported versions

Only the latest release and the `latest` image tag receive security fixes.

## Verifying images

Published images are signed keylessly with cosign and carry SPDX SBOM and SLSA build provenance attestations:

```sh
cosign verify \
  --certificate-identity-regexp '^https://github\.com/KrijnvanderBurg/gw2wrapper/\.github/workflows/rust\.yml@refs/(heads/main|tags/v.+)$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/krijnvanderburg/gw2wrapper:<tag>
gh attestation verify oci://ghcr.io/krijnvanderburg/gw2wrapper:<tag> --repo KrijnvanderBurg/gw2wrapper
```
