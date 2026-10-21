# Publishing Quick Apps

The plugin is distributed directly from this public repository. The marketplace
lists it; it does not host a separate compiled package. The repository root
contains the installable `manifest.json` and all runtime files.

## Prepare the source

1. Review the diff and run `npm test`, `npm run check`,
   `omarchy plugin validate .`, and the QML smoke test.
2. Confirm the compatibility matrix and release notes match the actual tests.
3. Check that `preview.png` shows only the menu and contains no private desktop
   contents, titles, history, or personal configuration.
4. Set the same version in `manifest.json`, `package.json`, and `CHANGELOG.md`.
5. Commit and push the approved source to the repository's default branch.
   Install/update commands fetch that branch; a GitHub release tag alone does
   not change what the current Omarchy installer fetches.

This preparation does not itself push, create a release, or submit a listing.

## Verify a clean installation

On a test desktop without a conflicting checkout:

```sh
omarchy plugin add https://github.com/Andean-Bridge/omarchy-quick-apps.git --enable
omarchy-shell shell summon andean-bridge.quick-apps '{}'
omarchy plugin disable andean-bridge.quick-apps
omarchy plugin enable andean-bridge.quick-apps
omarchy restart shell
```

Verify search, keyboard navigation, an existing app, a closed app, learned
ranking after restart, and removal using the README. Confirm installation has
not modified keybindings. Do not remove a user's existing development checkout
just to run a clean-install test.

## Tag and release

After the approved commit is on the default branch, create `v0.1.0` and a GitHub
release using the [prepared release notes](RELEASE-v0.1.0.md). Attach the same
source archive if desired; there is no compiled runtime asset. CI checks the
pure logic and distribution layout, while QML/compositor tests remain desktop
checks documented in the compatibility matrix.

## Submit to the marketplace

Use the official
[plugin submission form](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml)
and the [prepared submission text](MARKETPLACE-SUBMISSION.md):

- Repository: `https://github.com/Andean-Bridge/omarchy-quick-apps`
- Category: **Desktop**
- Tags: **Launcher**, **Quickshell**, **Hyprland**

The marketplace checks the exact published commit and requires maintainer
approval. Record the submitted SHA and avoid changing release claims while its
review is pending. Listing approval is not a security audit. For subsequent
updates, follow the marketplace's current verification/update form.

References: [publishing guide](https://plugins.omarchy.org/publish.html) and
[marketplace submission policy](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md).
