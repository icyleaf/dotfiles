# ADR-0001: Deploy Profile-Aware Secrets via `run_onchange` Script Rather Than Chezmoi Native Encrypted Files

**Status**: Accepted  
**Date**: 2026-07-23

## Context

Chezmoi has native age-encryption support: files prefixed `encrypted_` in the source directory are transparently decrypted on `chezmoi apply`. However, each source file maps to exactly one target file — there is no built-in mechanism to select between multiple encrypted source files for the same target path based on a runtime variable (such as `machine_profile`).

Two approaches were considered:

1. **Chezmoi native encrypted files** — one `encrypted_` file per target, decrypted transparently.
2. **`run_onchange` script using `age` CLI directly** — a lifecycle script that reads `{{ .machine_profile }}`, selects the correct `.age` file from `secrets/profiles/<name>/`, decrypts it with `age`, and writes the result to the target path.

## Decision

Use a `run_onchange_deploy-secrets.sh.tmpl` script (approach 2).

## Reasons

- **Profile selection is dynamic**: the same target path (`~/.config/zsh/local.zsh`, `~/.ssh/id_ed25519`) must receive different content depending on `machine_profile`. Chezmoi native encryption cannot express this — it would require one dedicated target path per profile, which is not the desired deployment shape.
- **SSH key filenames are fixed**: SSH clients expect keys at canonical paths (`~/.ssh/id_ed25519`). A per-profile source file naming scheme (`encrypted_private_dot_ssh/achron_id_ed25519`) would produce wrong target names without further renaming.
- **`run_onchange` re-triggers automatically**: by including a hash of the relevant encrypted files in the rendered template body, any change to a secret file causes the script to rerun on next `chezmoi apply`.

## Trade-offs Accepted

- Decryption is explicit (script) rather than implicit (chezmoi internals). This makes the mechanism visible and auditable but adds ~15 lines of shell.
- The `age` CLI must be present on the machine before `chezmoi apply`. This is acceptable: `age` is a prerequisite documented in the README bootstrap section.
