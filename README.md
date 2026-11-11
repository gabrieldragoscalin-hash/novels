# Dungeon — ten-floor prototype

A Godot **4.6.3 / GDScript** roguelite prototype for browser, desktop development,
and mobile browser testing. [Play on GitHub Pages](https://gabrieldragoscalin-hash.github.io/novels/).

[GAME_DESIGN.md](GAME_DESIGN.md) records the intended design.
[BALANCING.md](BALANCING.md) describes the implemented rules, defaults, controls,
seed reproduction, and what remains outside this ten-floor build.

## Play

Use the hub's **Play** tab and tap the central dungeon icon to enter. On iPhone, touch and drag anywhere to move; the joystick appears
under your finger. On desktop use WASD/arrows. Attacks aim and fire while moving.
Walk through doors; tap the action button or press **E** for services/chests/exits.

A fresh 5×5 map is generated per expedition. Its identities persist through ten
floors, with moving starts/bosses, tougher encounters, and rotating services.
Loot is unguarded on floor 1; defenders arrive on floor 2. Initially empty rooms
awaken with weaker enemies on floor 3. Floor 5 loot rooms have miniboss guardians. Defeating the tenth boss ends the expedition.

Core features: three enemy archetypes and ten distinct telegraphed floor bosses; XP pickups and upgrade
choices; coins/flares; loot, three trap effects, shop, trader, free upgrade, wheel,
healer; and a full-screen hub menu with an eight-slot **Inventory**, individual item copies,
parts upgrades, rarity synthesis, typed keys, chest pity, and coin-bought perks. Inventory shows four
slots on each side of the character, with locked Pet/Spirit spaces beneath.
Bottom tabs: **Shop, Inventory, Play, Perks, Miscellaneous**. Menus pause combat.
Six weapons have distinct arrows, beams, melee arcs, shockwaves and chaining discs.
Run cards include parallel projectiles, bursts, enemy ricochet, homing, obstacle
bypass, charged/split/explosive arrows, continuous lasers and meteors.
[WEAPONS_SPEC.md](WEAPONS_SPEC.md) records the exact rules. Doors stay open; room rewards and enemy
state cannot be farmed by revisiting.

Use [`?seed=9`](https://gabrieldragoscalin-hash.github.io/novels/?seed=9) to repeat a
layout for balance testing. These numbers are defaults, not a claim of fair balance.
The first illustrated Sanctuary art pack is implemented; art scope and remaining
work are recorded in [ART_DIRECTION.md](ART_DIRECTION.md). Advanced room adjacency
constraints, floors 11+, final art/audio, and cloud accounts are not implemented.

The shop has six daily coin offers and copper/silver/gold item chests with saved
35-open guarantees. Each floor pays typed keys for its first three daily clears.
All twelve permanent perks are active. Gems and tasks are reserved until
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
godot --headless --path . --script tests/cheats_smoke.gd
godot --headless --path . --script tests/balance_smoke.gd
```

Floor tests cover 80 seeds through all ten floors and actual projectile boss
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

## Testing cheats

Open **Miscellaneous → Cheat menu** in the hub, or **Cheats** during a run.
Combat pauses while the menu is open. Grant coins/gems/typed keys/parts, set chest
pity, reset daily allowances, create 1–20 copies of a selected item/rarity/stage,
unlock or max the four perks, or start a fresh test expedition on floor 1–10.
During runs: toggle god mode, heal, add flares/level choices, defeat the current
room with normal rewards, or teleport to any room/boss. Skipping floors grants
no clear rewards. God mode resets on a new run; equipment/perks apply on the next
run as usual. Wallet/item/perk changes are saved locally and remain after reload.
Gem grants here are testing controls, not task rewards or purchases. Cheats are
intentionally public in this prototype and should be removed before release.

Synthesis now filters the inventory to eligible ingredients after choosing a base.
Common requires identical copies too. **Quick synthesis** combines matching copies
through Rare bases (Rare→Epic), protecting equipped ingredients. In Cheats, use
**Add selected run upgrade** to test specific weapon combinations.

Combat balance now scales across ten floors. Rooms use mixed, swarm, crossfire,
heavy and two-wave ambush encounters. Shooters burst/fire fans, brutes charge and
recover, and bosses add ground attacks and a half-health phase from floor 3.
Boss access stays open. The run HUD shows active play time for balance testing;
menus and transitions do not count. See BALANCING.md for the current numbers.

Cheats now includes **Reset everything…**, with confirmation, to erase the local
profile and return to the starter bow. Rooms have about16% more playable area.
Equipment roles, lower chest/item odds and the latest modest HP increases are
recorded in BALANCING.md. Floor10/20 checkpoint starts are planned for later.

The latest combat stacking rules and repeatable weapon damage scenarios are in
[POWER_BALANCE.md](POWER_BALANCE.md). Run `tests/power_budget_smoke.gd` to check
weapon output, explosive/meteor overlap and charge-cooldown regressions.

New run cards: Vitality, Field medicine, Gatherer, Long reach, Last enemy, Momentum,
Emergency barrier, Salvage and rare Second Chance. Second Chance instantly revives
once at25% maxHP and never appears again in that run. Offers generally pair offense
with utility/defense. Brute HP is15% lower, boss/guardian HP20% lower, and play now
continues through floor10. Permanent perk cards can be tapped for their effects.

The Sanctuary art pack covers current floors1–10: painted room textures, transparent
hero/enemy/prop sprites, gradual corruption and matching hub character/portal art.
Approved later-region concepts are preserved under `art/concepts` and excluded
from browser downloads.

### Animated Sanctuary pass

The hero has distance-driven front/back walk cycles and release-driven attack
frames; mobs have walk/windup/attack poses. All six equipped weapons are visible
and animate per type, with a dedicated frontal inventory character holding them.
Six architectural templates arrange props around ceremonial routes, canals and
collapsed floors. Floors1–10 have unique boss silhouettes and attack
rotations. Boss animation currently uses windup/lunge transforms; dedicated boss
sprite animation sheets, death frames and armor cosmetics remain future work.
See [ART_DIRECTION.md](ART_DIRECTION.md) for atlas and boss details.

### Architectural rooms

Six authored room templates replace scattered props: a ceremonial hall, jade-water
sluice, fractured crypt, collapsed cloister, lava aqueduct and sunken courtyard.
Recessed canals have wall sources/drains and stone crossings. Terrain gaps block
walking/charges, while projectiles can pass over them. Solid props still block
shots. Enemy navigation follows the bridges, and all doors/services remain connected.
The existing cheat room picker can be used to inspect different room plans.
