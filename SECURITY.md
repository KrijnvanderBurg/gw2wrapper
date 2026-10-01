# Security Policy

## Supported Versions

This project is pre-1.0 and does not yet publish stable releases. Security fixes are applied to the `main` branch only.

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

Please do **not** open a public GitHub issue for security vulnerabilities.

Instead, report vulnerabilities privately using [GitHub Security Advisories](https://github.com/KrijnvanderBurg/gw2wrapper/security/advisories/new).

You can expect an initial response within 7 days. If the vulnerability is confirmed, we will work on a fix and coordinate disclosure with you before publishing details.

## Scope

This repository contains a Guild Wars 2 API client library/wrapper. In scope:

- Memory safety and `unsafe` code issues (note: `unsafe_code` is forbidden via lint).
- Dependency vulnerabilities (see [deny.toml](deny.toml)).
- Supply-chain integrity issues (see [supply-chain/config.toml](supply-chain/config.toml)).

Out of scope: vulnerabilities in the upstream Guild Wars 2 API itself.
