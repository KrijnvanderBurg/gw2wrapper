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
| `just deny` | Advisories, licenses, bans, build scripts, and sources |
| `just zizmor actionlint gitleaks typos hadolint shellcheck yamllint taplo-fmt just-fmt` | Repository linters |
| `just verify-image` | Build and test the melange package, build the apko image, scan with Trivy and Grype |
| `just repro-verify` | Build package and image twice; outputs must be bit-identical |
| `just run` | Run the image with a read-only root filesystem, no capabilities and `no-new-privileges` |

Formatters have `*-fix` variants (`fmt-fix`, `just-fmt-fix`, `taplo-fmt-fix`). `verify-image` runs on `pre-push`
(skip in an emergency with `SKIP=verify-image git push`; CI still runs it); everything else on `pre-commit`.

## CI/CD

- [rust.yml](.github/workflows/rust.yml): CI on PRs and `main` — checks, audits, repository lint, a native
  x86_64/aarch64 image build and scan, and multi-arch image assembly. Nothing is published.
- [release.yml](.github/workflows/release.yml): manual dispatch from `main` only. Builds and publishes the version
  currently in Cargo.toml to GHCR, keyless-signs it with cosign, attests SBOMs and SLSA provenance, verifies them,
  then tags `vX.Y.Z`; a no-op if that tag already exists.
- [maintenance.yml](.github/workflows/maintenance.yml): weekly signature check and re-scan of the published image,
  RustSec advisories re-check, and reproducible-build verification.
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
  --certificate-identity-regexp '^https://github\.com/KrijnvanderBurg/gw2wrapper/\.github/workflows/release\.yml@refs/heads/main$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/krijnvanderburg/gw2wrapper:<tag>
gh attestation verify oci://ghcr.io/krijnvanderburg/gw2wrapper:<tag> --repo KrijnvanderBurg/gw2wrapper
```
