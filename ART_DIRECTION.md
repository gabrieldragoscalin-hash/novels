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

The playable footprint remains464×438 world units. Room-specific collision rectangles and pathfinding follow six deterministic prop layouts.
Doors and hitboxes stay fixed; equipment and damage tuning are unchanged. Perspective comes from visible top faces, upright actors,
contact shadows and depth sorting; the navigation plane remains orthographic so
phone controls behave exactly as before. The original diamond-shaped concept
composition was adapted to an axis-aligned playable arena.

Characters are anchored at their feet. Actors, pillars and raised service/loot
props are sorted by their ground Y position so players can walk behind objects.
Pillar bases match existing collision footprints. Chests keep similar widths as
their lids open. The wheel uses a rotating procedural face over its painted base.
Outer map edges are closed visually; existing neighbor passages remain open.

The hero uses four-frame front/back walking cycles driven by distance traveled,
plus four front-facing attack frames synchronized to actual weapon releases.
Six held weapon sprites animate differently: bow draw/release, crossbow recoil,
wand thrust, sword sweep (alternating on extra slashes), hammer windup/slam,
and chakram spin. Back-facing attacks use the back sprite with animated weapons.
The inventory uses a dedicated full-frontal pose holding the equipped weapon.
Armor cosmetics are not implemented.

Normal acolytes, casters, brutes and guardians each have two walking poses,
a windup and an attack pose. Bosses have ten distinct painted silhouettes,
anchored anticipation/lunge transforms, readable warnings, hit flashes and recovery.
They do not yet have bespoke multi-frame directional sprite sheets.

Six stable room arrangements include memorial statues/pillars, sarcophagi,
reliquary urns, barricades, root gardens and braziers. A central cross preserves
all four door routes and access to services. Enemy navigation rebuilds on entry;
existing spawns inside props are projected to free navigation cells. Bases overlap
tight contact shadows rather than floating above detached ovals. Tall props fade
behind the player. The teal footprint remains visible above effects.

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

- `hero.png`:4×4 walking, attack, portrait and idle poses.
- `enemies.png`:4×4 two walk poses, windup and attack per enemy archetype.
- `bosses.png`:5×2 unique floor bosses.
- `objects.png`:4×3 six environment props and six held weapons.

## Remaining art work

Additional directional attack and death frames, bespoke boss animation sheets, armor cosmetics,
production weapon/equipment/card icons, further biome asset packs, bespoke trap
props, further room dressing, hub-wide illustrated scenery, and a final
sound/music pass remain. Current vector attack effects/telegraphs are retained
for gameplay clarity. Their replacement must preserve timing, area and contrast.

## Validation

`tests/art_smoke.gd` checks all16 atlas frames, transparency, cache reuse, overlay
center, stage progression and room collision and preserved player stats. Existing native
combat/progression tests still run. Browser checks cover movement through the new
art, actual late-floor encounters, inventory, phone/short-phone/desktop layout
and rendering errors. Visual review on a real iPhone remains valuable.

`tests/visuals_smoke.gd` validates all70 atlas regions, connected door/service paths
in every layout, boss identities/rotations and release-synchronized attack poses.
