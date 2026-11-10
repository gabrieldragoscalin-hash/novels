# Dungeon — First Steps

A Godot 4.6.3 roguelite prototype. The agreed concept is in [GAME_DESIGN.md](GAME_DESIGN.md).

## First playable

A connected 5×5 dungeon with 25 rooms, automatic ranged combat, an original placeholder adventurer,
angled wall/pillar artwork, collision, keyboard movement, and a floating touch
joystick. Walk into the centre of an open doorway to travel with a short fade.
A minimap highlights your current room in gold and visited rooms in teal; room
colours and coordinate markings help orientation. Doors at the outside of the
map are solid walls. Holding movement continues naturally after a transition.

This milestone starts in the safe room A1. Some rooms are empty; others have
1–3 chasing enemies. Your adventurer automatically fires at the nearest enemy
with a clear line of sight, even while moving. Pillars block shots and enemies
navigate around them. Enemies take three hits and deal contact damage, with a
short invulnerability window after you are hit. You have six health points.
Doors stay open so you can retreat. Enemy health and defeats persist on revisits;
projectiles disappear on room changes. A brief arrival grace period protects
against immediate contact damage. Combat pauses when the app loses focus.

Death offers a new run, and **Restart run** resets health, enemies, and exploration.
The layout and encounters remain deterministic for this prototype. Random room
types, random start/boss placement, XP/rewards, upgrades, melee, floor progression,
the hub, and persistent saves come later.

On iPhone: tap **Enter the dungeon**, then touch and drag anywhere on the game to move. The joystick appears beneath
your finger and disappears when released; interface buttons remain usable.
Release to stop. On desktop: use WASD or arrow keys. **Restart run** starts over in A1. Doorway arrows show available neighbouring rooms.

## Open locally

Import `project.godot` in **Godot 4.6.3**, then press F6/F5 to play.
No third-party assets or paid services are required.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/combat_smoke.gd
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
- `scripts/room.gd`: room drawing, collision, input, transitions, and interface.
- `scripts/dungeon.gd`: grid bounds, coordinates, and per-room encounter state.
- `scripts/combat.gd`: targeting, projectiles, enemy navigation, health, and damage.
- `tests/smoke.gd`: movement and room-travel checks.
- `tests/combat_smoke.gd`: combat, persistence, and death/restart checks.
- `tests/browser_smoke.py`: optional Chromium touch/keyboard checks (requires
  Playwright and Pillow). Serve the export on port 8765, then run
  `python3 tests/browser_smoke.py`; an alternate URL can be passed as an argument.
- `export_presets.cfg`: browser export configuration.

The first prototype uses procedural placeholder graphics. Its appearance is not
final art. Future combat and dungeon systems should be split into their own scenes
and scripts as they are introduced.
