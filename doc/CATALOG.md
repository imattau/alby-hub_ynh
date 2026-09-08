# Nostr Catalog checklist

This package is published through the Nostr Catalog rather than the official
YunoHost application catalog. No YunoHost-Apps transfer or official catalog
pull request is required.

The signed declaration binds this package to:

- app ID: `alby_hub`;
- package version from `manifest.toml`;
- the canonical public package repository and exact Git commit;
- the SHA256 hash of the exact `manifest.toml`;
- the SHA256 hash of the repository tree at that commit.

The package repository must be public, committed, and immutable at the
published ref before publication. The `[upstream]` URLs identify Alby Hub;
the package repository URL is the Git origin shown by the publisher and is
the authoritative source for catalogue verification.

## Required pre-publication checks

1. Commit all package changes and push the commit to the public `main` branch
   or a release tag.
2. Confirm the static-security workflow passes for that exact commit.
3. Confirm manifest validation, package linting, ShellCheck, and lifecycle
   tests pass on the supported `amd64` and `arm64` architectures.
4. Publish the signed declaration from the Nostr Catalog Publisher using the
   package repository URL and exact commit or tag.
5. If the catalogue trust policy requires a `package_check` attestation,
   publish it from a protected workflow using a dedicated verifier key.

Never commit the catalogue publisher private key or CI verifier private key.
Keep those identities separate.

## Package-specific notes

Alby Hub controls Lightning funds. A successful package install or catalogue
entry does not replace the user's recovery phrase backup. The package must be
tested through first-run setup, login, upgrade, backup/restore, and removal
without purge before it is treated as production-ready.
