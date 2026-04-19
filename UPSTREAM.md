# Upstream sync

This translation is based on the English original:

- **Repo:** https://github.com/beejjorgensen/bgnet
- **Commit:** `9fb2a78e12e71e1c38c4e6b6a2da2260f00ec5d2`
- **Version:** v3.3.2 (April 18, 2026)

Update this file when syncing from a newer upstream commit. The release
workflow reads it to embed provenance in the release notes.

## Release tags

We tag translation releases as:

    v<UPSTREAM_VERSION>-vi.<N>

For example, `v3.3.2-vi.1` is the first Vietnamese release based on
upstream v3.3.2. Subsequent translation fixes against the same upstream
version bump `N` (`v3.3.2-vi.2`, `v3.3.2-vi.3`, ...). When upstream bumps
their version, we restart `N` at 1 (`v3.3.3-vi.1`).

Use `scripts/release.sh` to create and push a tag; the
`.github/workflows/release.yml` workflow then builds and publishes a
GitHub Release with all artifacts.
