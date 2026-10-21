# Security review for 0.1.0

Reviewed runtime QML/JavaScript, process invocations, history/config handling,
development scripts, CI, documentation, dependencies, and the preview asset.
This is a focused code review and static preflight, not a security certification.

## Hardening applied before first publication

- Usage history now lives in a dedicated `0700` directory. Creation and
  permission checks complete before history is loaded or saved. It is never
  redirected to a shared fallback location after a permissions failure.
- GitHub Actions dependencies are pinned to full upstream commit SHAs. CI uses
  read-only contents permission, does not persist checkout credentials, has a
  ten-minute timeout, and cancels superseded runs.
- Window addresses are restricted to hexadecimal pointer values and workspace
  IDs to positive 32-bit integers before generating compositor dispatch calls.
  Tests cover metacharacters, oversized addresses, fractions, and infinities.

## Runtime boundaries checked

- App launches go through Omarchy's application library. Desktop-entry Exec
  strings are used for matching only; this plugin does not interpret them.
- Process arguments use argv arrays. No shell command is constructed from app
  names, titles, aliases, queries, or config values.
- Every visible Text element explicitly uses `Text.PlainText`; markup-shaped
  app names are included in regression coverage. There are no shared tooltip
  or notification text sinks.
- No downloads, telemetry, credentials, elevated commands, external source
  builds, service units, bundled executable binaries, or install hooks.
- Configuration is optional and external to the checkout; invalid types and
  values are normalized and bounded. Usage records are bounded, validated,
  and saved atomically. Only app identifiers, scores, and timestamps persist.
- The screenshot is cropped to the plugin surface and contains no desktop,
  window titles, personal messages, or usage timestamps.

## Marketplace baseline preflight

Used the marketplace's unmodified static analysis and scope modules from
`omacom/omarchy-plugin-marketplace` commit
`f9e45dc8c73d9778f5e70b760a4c99286f6145c6` (baseline policy version 3).
The local preflight reported no findings and no review capabilities across the
root README, runtime files, executable development scripts, and other relevant
files. Excluded documentation, tests, and CI were reviewed separately.

This local result does not replace the marketplace bot's exact-published-SHA
scan or its maintainer approval. The submission must bind that independent
result to the final upstream commit. No scanner policies or reports were
modified to change the outcome.
