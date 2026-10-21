# Compatibility

The target is Omarchy 4.0.6+ with its Quickshell shell and Lua-configured
Hyprland. This is not a standalone launcher for unrelated desktops.

| Surface | 4.0.6 | 4.5.0rc1 |
| --- | --- | --- |
| `menu` manifest kind and `keepLoaded` | Present | Present |
| Scoped app library (`shell.appLibrary`) | Present | Present |
| `sortedEntries`, `iconSource`, `launch` | Present | Present |
| Shared `Style`, `Color`, `BorderSurface` | Present | Present |
| Overlay | Local `QuickOverlay.qml` | Same local implementation |
| Strings | Session-locale catalogs, English fallback | Native `Commons.Translations`, live language changes |
| Keyboard reading direction | Local direction mapping | Same mapping, using native locale direction |

`NativeStrings.qml` is loaded only if the native translation component exists.
The main menu does not statically instantiate 4.5-only types, use its dock, or
depend on `Util.readingKey`. No absolute path to a developer's home is shipped.

## Checks performed

- Pure JavaScript tests for ranking, persistence format, cooldown/decay, config
  validation, duplicate launchers, aliases, terminal entries, and safe focus
  commands.
- Manifest validation with the installed Omarchy CLI.
- Isolated QML tests with upstream **v4.0.6** `Commons`/`Ui` components.
- Isolated QML tests with installed **4.5.0rc1-1** components.
- Live verification on 4.5.0rc1-1 with installed Quickshell
  **0.3.2.r7.g2b4501a-1** and Hyprland **0.56.2-4**.

The 4.0.6 test loads the actual upstream QML components using the installed
Quickshell/Hyprland runtime. It is not a full historical 4.0.6 VM or a guarantee
for every older dependency combination. Keep that distinction in release notes.

## Reproduce the component checks

```sh
scripts/smoke.sh /usr/share/omarchy/shell
scripts/smoke.sh /path/to/extracted/omarchy-v4.0.6/shell
```

The harness never launches Omarchy's `shell.qml`. It loads only this plugin with
stub app-library actions, temporary state/config, and the selected UI modules.
It does not send synthetic keystrokes or start lock/polkit/bar services. An
existing Wayland session is required. This test does not verify real app focus,
compositor keybindings, special workspaces, fractional scaling, or historical
Quickshell versions; those require a complete desktop test.

## Before advertising complete 4.0.6 support

Run on a disposable, fully updated 4.0.6 installation and check initial install,
enable/disable/removal, search, keyboard focus, actual app launching, cross-
workspace activation, theme changes, restart persistence, and multiple monitor
scales. Do not downgrade a user's working desktop as a compatibility test.
