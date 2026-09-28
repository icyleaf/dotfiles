# ADR-0005: Deploy All Base SSH Config Fragments Unconditionally

**Status**: Accepted  
**Date**: 2026-09-28

## Context

SSH `Host` entries are stored as encrypted fragments: shared ones under
`secrets/base/ssh_config.d/<group>/`, profile-only ones under
`secrets/profiles/<profile>/ssh_config.d/`.

The initial design gated base groups behind a per-profile whitelist
(`secrets/profiles/<profile>/ssh_config.groups`), so a machine only received the
groups named in its manifest, falling back to `common` when the manifest was
absent. This introduced a second source of truth: base fragments are already
encrypted to every age recipient (they are shared secrets), yet whether a
machine deployed them depended on a separate plaintext file that could be
missing or stale.

In practice this produced surprising gaps: a machine whose profile had no
manifest (for example a valid profile that simply lacked the file) silently
deployed `common` alone, leaving the other shared fragments unavailable.

## Decision

Deploy every fragment under `secrets/base/ssh_config.d/<group>/` on every
machine. If a fragment cannot be decrypted by the active age identity, skip it
(non-fatal) and continue. Remove the per-profile `ssh_config.groups` whitelist
and its manifest.

Profile-only fragments under `secrets/profiles/<profile>/ssh_config.d/` remain
selected by `machine_profile` as before.

## Reasons

- **Single source of truth**: base fragments are shared secrets encrypted to
  every recipient; deployment no longer depends on a parallel manifest.
- **Access control belongs to encryption**: what a machine may see is decided
  by which age recipients a file is encrypted to, not by a plaintext list that
  can drift.
- **Fail-soft**: an undecryptable fragment is skipped rather than aborting the
  whole run, so a future per-machine base fragment can coexist without edits.
- **Less machinery**: removes `read_groups`/`deploy_config_group`, the manifest
  file, and the related change-detection code.

## Trade-offs Accepted

- Every machine now receives all decryptable base groups; groups are purely
  organisational (filename namespacing). Per-machine host visibility is
  expressed by encrypting a fragment to that machine's key (base) or placing it
  under the profile directory.
- The `secrets/profiles/<profile>/ssh_config.groups` concept (**Profile SSH
  Whitelist**) is retired from the domain model.

## Supersedes

- The profile SSH whitelist introduced by commit `75f4401`
  ("feat(secrets): manage SSH config as encrypted per-profile fragments").
  ADR-0001 (profile-aware secrets via `run_onchange`) still applies.
