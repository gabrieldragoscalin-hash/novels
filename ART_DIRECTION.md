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

- `art/sanctuary/room.png`: quiet jade floor, worn-gold inlay, ivory perimeter trim.
  No baked characters, collision props, text or fixed gameplay objects.
- `art/sanctuary/corruption.png`: transparent border growth with clear center and
  cardinal doorway gaps. Appears gradually from floor4, reaching full grade at10.
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

The playable footprint remains464×438 world units. Room-specific collision rectangles and pathfinding follow six authored architectural templates.
Doors and hitboxes stay fixed; equipment and damage tuning are unchanged. Perspective comes from visible top faces, upright actors,
contact shadows and depth sorting; the navigation plane remains orthographic so
phone controls behave exactly as before. The original diamond-shaped concept
composition was adapted to an axis-aligned playable arena.

Characters are anchored at their feet. Actors, pillars and raised service/loot
props are sorted by their ground Y position so players can walk behind objects.
Pillar bases match existing collision footprints. Chests keep similar widths as
their lids open. The wheel uses a rotating procedural face over its painted base.
Outer map edges are closed visually; existing neighbor passages remain open.

The hero now uses `hero_rig.png`, a4×4 sheet of isolated head, torso, upper arm,
forearm, gripping hand, thigh, boot/shin and cape pieces in front/back views.
`hero_animation.gd` interpolates a continuous locomotion phase and independent
arm/weapon targets. Body-part sizes and attachment origins stay fixed throughout
walking, aiming and attacking. Two-link IK joins the shoulders, elbows and hands;
hands overlap the actual weapon grip instead of a weapon being pasted over an
idle full-body image. Facing uses hysteresis and an opaque orientation blend.
Pausing, extra shots, attacks and turns do not reset the walking phase.

Bow draw/string release, crossbow recoil, wand casting/continuous laser, sword
windup/sweep, hammer windup/slam and chakram throwing use different target motions.
Attack preparation follows the existing firing cadence; actual release events
trigger recovery. Projectiles originate visually at the weapon muzzle/grip and
converge toward the existing enemy hit plane. Gameplay trajectories and damage
remain controlled by combat code.

The inventory uses `inventory.png`, a3×2 sheet of complete front-facing portraits
holding bow/crossbow/wand/sword/hammer/chakram. Arms, hands and weapon are painted
together in a natural holding pose. Equipment cosmetics beyond weapon type remain
future work. The previous whole-body walking sheet is retained as legacy source
art but is no longer used by the player renderer.

Normal acolytes, casters, brutes and guardians each have two walking poses,
a windup and an attack pose. Bosses have ten distinct painted silhouettes,
anchored anticipation/lunge transforms, readable warnings, hit flashes and recovery.
They do not yet have bespoke multi-frame directional sprite sheets.

Six authored architectural plans replace scattered quadrant props. Their routes,
terrain blockers, crossings and props are defined together in `room_layouts.gd`:

| Room | Composition and movement |
| --- | --- |
| Processional Hall | Paired statues/columns frame a central ceremonial aisle. |
| Jade Sluice | A wall outlet feeds a recessed jade-water canal; one central stone bridge connects the banks before a wall drain. |
| Fractured Crypt | Paired sarcophagi frame a floor-wide rupture crossed by a surviving stone span. |
| Collapsed Cloister | Opposing collapsed floor sections leave an intact route around their broken edges. |
| Lava Aqueduct | A wall vent pours molten flow down a masonry canal to a drain; one transverse bridge connects the two sides. |
| Sunken Courtyard | Four recessed water basins frame a central platform, axial crossings and outer walkways. |

Templates remain stable per room across floors. Rendering (`room_architecture.gd`)
uses the same terrain and bridge rectangles as navigation: stone lips, recessed
channel walls, fractured slab edges, crossing blocks, sources and drains explain
the room's structure. Existing painted props are arranged as pairs, bankside
fixtures or monuments around those structures. Bases overlap contact shadows;
tall props fade behind the player and the teal footprint stays visible above effects.

Floor gaps block the player, ground enemies and charges. They do not stop shots;
solid props still provide cover. Bridges are the only bank-to-bank routes in the
Sluice, Crypt and Aqueduct. All walkable navigation cells connect to all doors and
the central interaction point. Spawn positions inside terrain project to the
nearest free navigation cell. Gaps currently prevent entry rather than applying
falling/lava damage. The architecture pass does not add flying enemies or jumping.

Floors1–3 use the clean Sanctuary palette; floors4–10 gain crimson border roots.
Future region packs reuse the catalog interface.

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
- `hero_rig.png`:4×4 isolated front/back body parts for continuous animation.
- `inventory.png`:3×2 complete weapon-holding portraits.
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
