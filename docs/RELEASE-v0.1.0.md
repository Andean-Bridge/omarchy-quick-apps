# Quick Apps 0.1.0

A compact launcher for Omarchy that learns which apps you use most.

- Eight apps in two rows of four, with search across all installed apps.
- Open apps or focus existing windows across workspaces.
- Arrow keys, Enter, mouse selection, and Alt+1–8.
- Local learning with configurable cooldown and gradual score decay.
- Starter apps, exclusions, and class aliases in an update-safe config file.
- Native Omarchy styling, English/Spanish, and 4.0.x UI compatibility fallbacks.

Install:

```sh
omarchy plugin add https://github.com/Andean-Bridge/omarchy-quick-apps.git --enable
```

Add a shortcut using the README; installation does not change your bindings.

Validated on Omarchy 4.5.0rc1-1. QML integration also passes with 4.0.6 shell UI
components on the installed runtime; a complete 4.0.6 desktop remains unverified.
See docs/COMPATIBILITY.md for the exact scope. No extra runtime dependencies,
network requests, or telemetry. MIT license.
