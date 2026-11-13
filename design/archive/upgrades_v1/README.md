# Upgrade system v1 archive

Complete playable baseline: `0b05723e6b2d778a9c20af2dfe4560e2971f8079`.
Git tag: `upgrades-v1-before-nine-weapons`.

This archive contains the old upgrade catalog, combat delivery code, balance, visual integration, documentation and original Godot tests. Source snapshots end in `.txt` so Godot does not load them.

For a complete rollback, create a branch from the tag:

```sh
git switch -c restore-upgrades-v1 upgrades-v1-before-nine-weapons
```

To compare changes, use `git diff upgrades-v1-before-nine-weapons -- scripts`. Do not copy only the catalog over the new combat code: the old attack semantics differ. Existing account equipment saves are preserved by the new system.
