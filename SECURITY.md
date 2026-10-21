# Security and privacy

Quick Apps runs with the same user permissions as Omarchy's shell plugins. It
reads desktop entries, observes active application identifiers, saves local
aggregate usage, and invokes `hyprctl` or Omarchy's app library to open/focus apps.
It makes no network requests, downloads no executables, installs no service, and
does not request elevated privileges.

Usage history is written atomically inside a dedicated directory whose mode is
set to `0700` before loading or saving. A permissions failure disables history
persistence rather than falling back to a shared location. CI dependencies are
pinned to full commit SHAs and workflows use read-only repository permissions.

Report a vulnerability through this repository's **Security → Report a
vulnerability** option when available. If private reporting is unavailable,
contact an Andean Bridge repository maintainer before posting exploit details
publicly. Never include real usage history or credentials in a report.

An app's desktop entry is executable configuration managed by the user/package
manager. Quick Apps delegates launches to Omarchy rather than interpreting its
Exec string itself. Window addresses and workspace numbers are validated before
being placed in Lua dispatcher expressions. External app names are displayed
with `Text.PlainText`.
