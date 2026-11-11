# Dungeon — three-floor prototype

A Godot **4.6.3 / GDScript** roguelite prototype for browser, desktop development,
and mobile browser testing. [Play on GitHub Pages](https://gabrieldragoscalin-hash.github.io/novels/).

[GAME_DESIGN.md](GAME_DESIGN.md) records the intended design.
[BALANCING.md](BALANCING.md) describes the implemented rules, defaults, controls,
seed reproduction, and what remains outside this three-floor build.

## Play

Use the hub's **Play** tab and tap the central dungeon icon to enter. On iPhone, touch and drag anywhere to move; the joystick appears
under your finger. On desktop use WASD/arrows. Attacks aim and fire while moving.
Walk through doors; tap the action button or press **E** for services/chests/exits.

A fresh 5×5 map is generated per expedition. Its identities persist through three
floors, with moving starts/bosses, tougher encounters, and rotating services.
Loot is unguarded on floor 1; defenders arrive on floor 2. Initially empty rooms
awaken with weaker enemies on floor 3. Defeating the third boss ends the expedition.

Core features: three enemy archetypes and a telegraphed boss; XP pickups and upgrade
choices; coins/flares; loot, three trap effects, shop, trader, free upgrade, wheel,
healer; and a full-screen hub menu with an eight-slot **Inventory**, individual item copies,
parts upgrades, rarity synthesis, typed keys, chest pity, and coin-bought perks. Inventory shows four
slots on each side of the character, with locked Pet/Spirit spaces beneath.
Bottom tabs: **Shop, Inventory, Play, Perks, Miscellaneous**. Menus pause combat.
There are 13 temporary run upgrades, including critical hits, multishot, ricochet,
frost, burn, regeneration and XP bonuses. Doors stay open; room rewards and enemy
state cannot be farmed by revisiting.

Use [`?seed=9`](https://gabrieldragoscalin-hash.github.io/novels/?seed=9) to repeat a
layout for balance testing. These numbers are defaults, not a claim of fair balance.
Art is original procedural placeholder graphics. Melee, advanced room adjacency
constraints, floors 4+, final art/audio, and cloud accounts are not implemented.

The shop has six daily coin offers and copper/silver/gold item chests with saved
35-open guarantees. Each floor pays typed keys for its first three daily clears.
Four perks are active; eight remain reserved. Gems and tasks are reserved until
defined. [ECONOMY_SPEC.md](ECONOMY_SPEC.md) records recipes, rewards, odds and
prototype prices. Progress is saved locally; old equipment levels are preserved.

## Develop and test

Import `project.godot` in Godot 4.6.3 and press F5. No external assets are needed.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/combat_smoke.gd
godot --headless --path . --script tests/progression_smoke.gd
godot --headless --path . --script tests/floors_smoke.gd
godot --headless --path . --script tests/services_smoke.gd
godot --headless --path . --script tests/equipment_smoke.gd
godot --headless --path . --script tests/upgrades_smoke.gd
godot --headless --path . --script tests/hub_menu_smoke.gd
godot --headless --path . --script tests/economy_smoke.gd
godot --headless --path . --script tests/synthesis_smoke.gd
```

Floor tests cover 80 seeds through all three floors and actual projectile boss
kills. Service tests cover wheel outcomes, traps, finite rewards, and local saves. Equipment tests check legacy saves, loadouts and parts upgrade
costs; economy tests cover daily rewards, chest pity, migration, and perk unlocks;
synthesis tests cover all eight recipes and ingredient protection. Upgrade tests exercise combat effects.
`tests/describe_run.gd` prints the seed-9 map used by the browser checks.

## Export and deploy

Pushes to `main` trigger `.github/workflows/pages.yml`, which installs a pinned,
checksum-verified Godot release, runs runtime tests, exports, and deploys Pages.
Set **Settings → Pages → Source → GitHub Actions**. The single-threaded
Compatibility-renderer Web export needs no cross-origin-isolation headers.

For local browser testing, install matching Godot export templates:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8765 --directory build/web
```

Serve over HTTP; do not open the exported HTML as a local file.
Optional browser checks require Playwright, Pillow, and an installed Chromium:
`python3 tests/browser_smoke.py` (or pass an alternate served URL). They exercise
mobile input, doors, services, purchases, upgrades, and the hub. `python3 tests/browser_hub_layout.py` checks phone, short-phone and desktop hub
layouts. Actual iPhone Safari remains part of device testing. Local progress is specific to the browser
and origin; it is not synchronized across devices.

Scripts are separated into dungeon generation, combat, progression, services,
hub/equipment persistence, and the room/interface controller under `scripts/`.
