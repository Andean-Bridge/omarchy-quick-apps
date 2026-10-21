# Contributing

Open an issue describing the behavior and your Omarchy/Quickshell/Hyprland
versions, or submit a pull request with a focused change.

Run `npm test`, `npm run check`, `omarchy plugin validate .`, and
`scripts/smoke.sh "$OMARCHY_PATH/shell"` before proposing a change. Node.js 20+
and Python 3 are needed for the offline checks; no npm install is necessary.

Keep app usage local, render app names as plain text, and pass process arguments
as argv arrays. Do not add install hooks, automatic shortcut changes, personal
profile assumptions, or edits to packaged Omarchy files.

Keep ranking, matching, and config logic in the pure JavaScript modules so it can
be tested outside Quickshell. Add strings to both English and Spanish catalogs;
new languages are welcome. Continue supporting shell components from 4.0.6, or
explicitly document and test a new minimum version.

For a live test, copy the repository into a user-owned plugin directory or use
Omarchy's git installer after the source is published. Test lifecycle, search,
an existing window, a closed app, disable/re-enable, and persistence. Use the
shell's `call ... setQuery` and `call ... activate` controls instead of simulated
typing that could reach an unrelated application.

Do not include real usage history, personal configuration, private window
titles, credentials, or uncropped desktop screenshots in commits.
