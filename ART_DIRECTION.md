# Art direction and production pipeline

Approved direction: original illustrated three-quarter dark fantasy, with strong
inked shapes, painterly planes, rich color and readable silhouettes. Worn beauty
becomes corrupted architecture, then infernal industry, living depths and cosmic
royal emptiness. The world can extend beyond50/100; floor10 is an early descent.

## Region references

| Floors | Region | Reference |
| --- | --- | --- |
|1–10|The Fallen Sanctuary|art/concepts/01_fallen_sanctuary.png|
|11–20|The Crimson Court|art/concepts/02_crimson_court.png|
|21–30|The Ashen Foundries|art/concepts/03_ashen_foundries.png|
|31–40|The Living Depths|art/concepts/04_living_depths.png|
|41–50|The Hollow Throne|art/concepts/05_hollow_throne.png|

These five approved images are concept references, not gameplay scenes. Only
Fallen Sanctuary currently has production assets; gameplay still ends at floor10.
Launch target50 floors, future direction100 and additional game modes. Regions
beyond50 have no approved artwork yet. Do not stretch Sanctuary into a final hell.

## Current production pack

Source PNGs are original image-generation outputs created for this project from
the approved concept. They are copied intact; no third-party asset pack is needed.

- `art/rooms/00_*.png` through `09_*.png`: ten complete production room backgrounds.
- `art/sanctuary/arena_floor.png`, `masonry.png`, `surfaces.png`, `room.png`
  and `corruption.png`: legacy source art; not used to construct current rooms.
- `art/sanctuary/actors.png`: transparent4×2 atlas. Reading order: hero front,
  hero back, chaser, shooter, brute, boss, treasure guardian, merchant.
- `art/sanctuary/props.png`: transparent4×2 atlas. Pillar, closed/open chest,
  merchant stall, healing font, upgrade altar, wheel pedestal, exit portal.

Runtime regions live in `scripts/art_regions.gd`; the art catalog/region ranges
live in `scripts/game_art.gd`. The raw atlases are1774×887, so equal cells must use
floored boundaries rather than assuming dimensions divide exactly by4 and2.

To regenerate frame bounds after replacing an atlas:

```
godot --headless --path . --script tools/build_art_regions.gd
```

The tool analyzes alpha>=32 plus2 source pixels of padding to ignore faint stray
transparent pixels. It also measures the opaque bottom6% of actor frames to anchor feet independently
of trailing capes. It writes UV/pivot metadata only; source images are never edited.
Runtime loads cached AtlasTextures, with no full-atlas CPU readback or per-frame
image scanning. Atlas textures are clipped to avoid neighboring-cell bleeding.

Concept references have `.gdignore` and are excluded from the Web export. Runtime
uses the production PNGs, not the full-resolution presentation sheets.

## Gameplay integration

The playable footprint remains464×438 world units. Room-specific collision rectangles and pathfinding follow ten complete painted room templates.
Doors and hitboxes stay fixed; equipment and damage tuning are unchanged. Perspective comes from visible top faces, upright actors,
contact shadows and depth sorting; the navigation plane remains orthographic so
phone controls behave exactly as before. The original diamond-shaped concept
composition was adapted to an axis-aligned playable arena.

Characters are anchored at their feet. Actors and raised service/loot props are
sorted by ground Y. Fixed room scenery belongs to the complete background. Chests keep similar widths as
their lids open. The wheel uses a rotating procedural face over its painted base.
Outer map edges are closed visually; existing neighbor passages remain open.

The hero now uses `art/champions/aster_rig.png`, a4×4 sheet of isolated head, torso, upper arm,
forearm, gripping hand, thigh, boot/shin and cape pieces in front/back views.
`hero_animation.gd` interpolates a continuous locomotion phase and independent
arm/weapon targets. Body-part sizes and attachment origins stay fixed throughout
walking, aiming and attacking. Two-link IK joins the shoulders, elbows and hands;
hands overlap the actual weapon grip instead of a weapon being pasted over an
idle full-body image. Facing uses hysteresis and a single opaque body view.
Pausing, extra shots, attacks and turns do not reset the walking phase.

Bow draw/string release, crossbow recoil, wand casting/continuous laser, sword
windup/sweep, hammer windup/slam and chakram throwing use different target motions.
Attack preparation follows the existing firing cadence; actual release events
trigger recovery. Projectiles originate visually at the weapon muzzle/grip and
converge toward the existing enemy hit plane. Gameplay trajectories and damage
remain controlled by combat code.

The inventory uses `art/champions/aster_inventory.png`, a3×2 sheet of complete front-facing portraits
holding bow/crossbow/wand/sword/hammer/chakram. Arms, hands and weapon are painted
together in a natural holding pose. Equipment cosmetics beyond weapon type remain
future work. The previous whole-body walking sheet is retained as legacy source
art but is no longer used by the player renderer.

Normal acolytes, casters, brutes and guardians each have two walking poses,
a windup and an attack pose. Bosses have ten distinct painted silhouettes,
anchored anticipation/lunge transforms, readable warnings, hit flashes and recovery.
They do not yet have bespoke multi-frame directional sprite sheets.

Ten complete room paintings replace the modular floor/prop construction. Each
background contains its own paving, fixed scenery, walls, doorway recesses,
terrain edges, crossings, shadows and reflected light in one coherent image.

| Room | Composition |
| --- | --- |
| Quiet Sanctuary | Intact jade slabs and ceremonial gold inlay. |
| Weathered Flagstones | Dry fractured slabs, worn sun engraving and mossy joints. |
| Broken Corners | Two collapsed floor sections with exposed stone depth. |
| Split Crypt | A transverse chasm with one central stone crossing. |
| Jade Waterway | A wall-fed water canal with a central bridge and drain. |
| Molten Aqueduct | A north–south lava channel crossed by a broad east–west bridge. |
| Drowned Court | Four sunken water basins around connected axial walkways. |
| Ruined Cloister | Two low carved stone foundations embedded in the paving. |
| Twin Watercourses | Two parallel channels with broad central crossings. |
| Ember Crossing | A wall-fed lava canal with one central bridge. |

Templates remain stable per room across floors, with all ten used in each 5×5
map. Backgrounds are cached single textured quads (`room_backdrop.gd`), not
compositions of crack decals, tiled masonry, detached pillars or liquid overlays.
Only illumination of the existing painted doorway recesses changes with exits.
Inactive recesses remain dark; they do not render another wall/arch in the arena.

`scripts/room_layouts.gd` contains collision traced against the final paintings.
Gaps block bodies and charges but allow shots; side walls and the low Cloister
masonry stop both. All entrances, the central interaction area and default spawn
positions remain reachable. Blocked enemy spawns project to free navigation cells.
Lava and holes currently prevent entry rather than inflicting terrain damage.

These ten backgrounds cover the Fallen Sanctuary region. The earlier crimson
root overlays are not applied to the new paintings. Later regions need their own
complete background sets; the catalog can be extended without replacing combat.

### Floor bosses

| Floor | Boss | Attack rotation |
| --- | --- | --- |
| 1 | The Headsman | Aimed fan, charge |
| 2 | Jade Oracle | Ring, locked ground marks, fan |
| 3 | Sanctuary Hound | Charge, marked hunt trail, charge |
| 4 | Bell Wraith | Ring, cross volley, ground marks |
| 5 | Cathedral Titan | Cross-shaped eruptions, charge, ground marks |
| 6 | Thorn Hierophant | Spiral volley, fan, ground marks |
| 7 | Jade Scorpion | Hunt trail, cross volley, charge |
| 8 | Mirror Queen | Cross volley, ring, fan |
| 9 | Cinder Stag | Charge, eruptions, spiral |
| 10 | Fallen Regent | Ground/fan combo, ring, hunt, spiral |

Ring/cross/spiral volleys lock orientation at warning start. Ground/hunt/eruption
markers lock positions with at least0.9s warning. Enrage keeps the established
half-health cadence increase. HP, damage, rewards and player power budgets remain
unchanged; the new rotations need continued playtesting for dodge difficulty.

### Added atlases

- `hero.png`:4×4 legacy whole-body poses, retained as source artwork.
- `art/champions/aster_rig.png`:4×4 isolated front/back body parts for continuous animation.
- `art/champions/aster_inventory.png`:3×2 complete weapon-holding portraits.
- `enemies.png`:4×4 two walk poses, windup and attack per enemy archetype.
- `bosses.png`:5×2 unique floor bosses.
- `objects.png`:4×3 six environment props and six held weapons.

## Remaining art work

Additional directional attack and death frames, bespoke boss animation sheets, armor cosmetics,
production weapon/equipment/card icons, further biome asset packs, bespoke trap
props, further room dressing, hub-wide illustrated scenery, and a final
sound/music pass remain. Attack effects use the painted animation atlases below. Warning markers remain
vector-based for timing/area clarity, and firing ground hazards show a painted blast.

## Validation

`tests/art_smoke.gd` checks all16 atlas frames, transparency, cache reuse, overlay
center, stage progression and room collision and preserved player stats. Existing native
combat/progression tests still run. Browser checks cover movement through the new
art, actual late-floor encounters, inventory, phone/short-phone/desktop layout
and rendering errors. Visual review on a real iPhone remains valuable.

`tests/visuals_smoke.gd` validates the production atlas regions, connected door/service paths
in every layout, boss identities/rotations and release-synchronized attack poses.

`tests/architecture_smoke.gd` floods every walkable navigation cell, checks door,
service and spawn access, proves the sole crossings are necessary, and exercises
enemy bridge traversal/charge blocking and projectile visibility over gaps.
`tests/browser_architecture.py` renders all six plans and checks that the player
cannot walk through water but can cross its bridge in the exported mobile game.

`tests/animation_smoke.gd` checks walking continuity across rapid attack releases,
wrist speed bounds, connected IK joints, distance/FPS consistency and facing
hysteresis. Browser weapon/motion tests capture all six inventory poses, attacks,
walking and movement during combat; set RECORD_ANIMATIONS=1 to record videos when
Playwright's ffmpeg runtime is available.

Next requested milestone after in-game animations: rename/rework items, create
all item sprites, then update menus and the home GUI.

## Animated attack effects

Three transparent4×4 production atlases provide48 fixed-registration animation
frames. `vfx_impact.png` contains an8-frame ignition/fire/debris/smoke explosion,
falling meteor frames and rolling volcanic rock frames. `vfx_strikes.png` contains
blade-ribbon slashes, erupting-stone shockwaves, flowing rune/filament lasers and
physical spinning jade/gold chakrams. `vfx_shots.png` contains feathered arrows,
heavy crossbow bolts, magical lances and hit sparks. These replace the old circle,
cone and thick-line attack placeholders. Telegraphs remain distinct gameplay cues.

`attack_vfx.gd` caches fixed-cell AtlasTextures; frames never normalize themselves
to different opaque bounds. `attack_renderer.gd` advances frames alongside travel,
spin and impact progress. Falling meteors have a landing flash, flame trail and
clipped entry from above the room, followed by the animated blast. Ordinary and
charged projectile sizes remain distinct; impact art follows the damage geometry.

Presentation has explicit budgets:24 visible falling meteors,48 ordinary
projectiles plus24 rolling rocks,48 active rendered effects and24 hit sparks.
Near-overlapping blasts share visuals, and stored transient effects cap72.
Sampling/coalescing is presentation-only: all meteor impacts still resolve.

Rolling meteor physics uses swept collision and a per-cycle/per-frame eligibility
cache rather than repeating5px collision substeps for every rock. Eligible lists
refresh every update so newly active reinforcements still take damage. Shared
per-cycle splash/rolling damage limits, attack cadence and rewards remain intact.
The maximum-upgrade900-frame native workload improved from roughly9.5s to2.3s
on this executor before browser rendering; this is not a measured iPhone FPS claim.

`tests/attack_vfx_smoke.gd` validates all48 frames, sampling budgets, damage despite
merged visuals and rolling collisions/reinforcement activation. `attack_stress.gd`
exercises Meteor Rain, parallel shots, salvos, haste, enlarged meteors and rolling
rocks together. `browser_attack_vfx.py` grants builds through the real cheat menu
and captures explosive arrows, Perpetuum and maximum-upgrade meteors.

## Complete room background implementation

See [ROOM_REFERENCES.md](ROOM_REFERENCES.md) for reference context. Production art
is in `art/rooms/`; the previous arena-floor and masonry atlases are legacy source
assets only. Static room geometry renders once per entry in a negative-Z
CanvasItem. Actors, loot, services and combat effects render independently.
`tests/arena_style_smoke.gd` validates all ten backgrounds, map coverage, exit
lighting and the cached draw lifecycle. Architecture tests check connected floor,
bridge necessity, cover, spawns and navigation; the browser gallery checks all ten.

## Tower home and mortal champion

`art/hub/tower.png` is one complete portrait environment with the Sanctuary crown
and a visible infernal transition below. It remains top-aligned inside the home
view so the spire does not collide with the title on short screens. Header,
journal and navigation controls are separate, functional UI elements.
`hell_banner.png` supplies the volcanic battlepass landscape; `parchment.png`
frames the four journal buttons. `icons.png` is a transparent 4×3 atlas of twelve
painted menu icons. `tools/build_hub_regions.gd` generates tight clipped UVs without
editing source pixels. Jade panels, gold borders and DejaVu Serif headings unify
the menus; the font and its license ship under `art/fonts/`.

Aster's identity sheet, modular 4×4 rig and 3×2 inventory poses are in
`art/champions/`. Sun-bronze armor, bare warm-skinned arms, dark hair and a short
crimson cloak separate him from the hooded cool-colored dungeon acolytes. Each
inventory pose includes the actual held weapon and painted hand grips. Animation
still uses the existing continuous stride and IK/release system. Previous hooded
hero sheets remain legacy sources only.

Before publishing: native home/settings/persistence tests, all gameplay suites,
three-size browser menu captures, profile/modal interactions, six-weapon inventory
review, and walking/attacking captures. See `tests/home_smoke.gd`,
`tests/browser_home.py`, `tests/browser_hub_layout.py` and
`tests/browser_animation_motion.py`.

## Weapon-grip and bonus-room cleanup

The human rig uses shorter outward-bending arms, wrist-aligned mirrored hands,
leading-shoulder selection when turning, and a single facing body at a time.
Shoulder roots render beneath the cuirass; held weapons and gripping fingers
remain visible above it. Bow/crossbow/hammer contacts are solved together inside
both arm reach circles. Weapon UV grips now use both axes: chakrams are held at
the rim, crossbows at the stock grip, and heavy weapons along their handles.
Continuous walking/release timing and gameplay damage remain unchanged.

Trader and free-upgrade rooms have no crystal pedestal. The upgrade room stays
clear pending the bonus-room redesign; its existing upgrade interaction remains.
The trader is a distinct unarmed travelling merchant with a visible face, cap,
ledger, purse and pack, standing at (120,385), away from the room center. Shop
NPCs use this merchant art too; their existing stall remains. The position is
checked against all ten room collision plans. Services/rewards are unchanged.
