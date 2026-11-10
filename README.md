# Dungeon — First Steps

A Godot 4.6.3 roguelite prototype. The agreed concept is in [GAME_DESIGN.md](GAME_DESIGN.md).

## First playable

One room with an original placeholder adventurer, angled wall/pillar artwork,
collision, keyboard movement, and a floating touch joystick. Combat, room travel,
dungeon generation, progression, and saves are not implemented yet.

On iPhone: tap **Enter the dungeon**, then drag in the area below the room to move.
Release to stop. On desktop: use WASD or arrow keys. **Reset position** returns you
to the entrance. The doorway is decorative in this milestone.

## Open locally

Import `project.godot` in **Godot 4.6.3**, then press F6/F5 to play.
No third-party assets or paid services are required.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/smoke.gd
```

## Browser build and GitHub Pages

The workflow in `.github/workflows/pages.yml` builds and deploys on pushes to
`main`, or from **Actions → Build and deploy game → Run workflow**. Set
**Settings → Pages → Source → GitHub Actions**. A branch-based Pages source will
not deploy this Godot project correctly. The workflow downloads the pinned editor
and templates from the official Godot release and checks their published SHA-512
checksums before use.

Expected project URL after a successful deployment:
https://gabrieldragoscalin-hash.github.io/novels/

For a local export, install the matching Godot export templates, then:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

Open the served page through HTTP rather than opening `index.html` as a file.
The export uses the Compatibility renderer and **single-threaded WebAssembly**,
so GitHub Pages does not need cross-origin-isolation headers. Actual iPhone
Safari performance and touch behaviour still need device testing.

## Project layout

- `scenes/room.tscn`: entry scene.
- `scripts/room.gd`: room drawing, collision, input, and prototype interface.
- `tests/smoke.gd`: automated runtime checks.
- `tests/browser_smoke.py`: optional Chromium touch/keyboard checks (requires
  Playwright and Pillow). Serve the export on port 8765, then run
  `python3 tests/browser_smoke.py`; an alternate URL can be passed as an argument.
- `export_presets.cfg`: browser export configuration.

The first prototype uses procedural placeholder graphics. Its appearance is not
final art. Future combat and dungeon systems should be split into their own scenes
and scripts as they are introduced.
