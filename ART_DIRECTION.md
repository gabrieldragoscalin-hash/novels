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
uses just the four production PNGs, not the full-resolution presentation sheets.

## Gameplay integration

The playable footprint remains464×438 world units. Collision rectangles,
pathfinding, doors, spawn positions, hitboxes and all combat/economy tuning remain
independent of artwork. Perspective comes from visible top faces, upright actors,
contact shadows and depth sorting; the navigation plane remains orthographic so
phone controls behave exactly as before. The original diamond-shaped concept
composition was adapted to an axis-aligned playable arena.

Characters are anchored at their feet. Actors, pillars and raised service/loot
props are sorted by their ground Y position so players can walk behind objects.
Pillar bases match existing collision footprints. Chests keep similar widths as
their lids open. The wheel uses a rotating procedural face over its painted base.
Outer map edges are closed visually; existing neighbor passages remain open.

The hero has front/back idle poses, horizontal facing and subtle movement bob.
Enemies have distinct silhouettes, idle motion, recovery tint and hit flashes.
These are not full walk/attack sprite animations. Inventory uses the same hero;
its appearance does not yet change with each armor item. The hub entry previews
Sanctuary flooring and a painted portal. Raised props fade when the player is behind them. A small teal footprint ring
is drawn above effects/props to keep the player readable while partly occluded. Health bars, aim/charge tells, spawn warnings and
ground hazards stay high-contrast and are not baked into room art.

Floors1–3 use the clean Sanctuary palette. Later floors receive subtle grading
and increasingly visible crimson border roots. This remains region1, not the
floor41–50 climax. Room variants have small palette shifts without changing
geometry. Region2–5 production packs can use the same atlas/layout interface.

## Remaining art work

Full directional walking/attack/death animations, equipped-item cosmetics,
production weapon/equipment/card icons, further biome asset packs, bespoke trap
props, more room dressing and layouts, hub-wide illustrated scenery, and a final
sound/music pass remain. Current vector attack effects/telegraphs are retained
for gameplay clarity. Their replacement must preserve timing, area and contrast.

## Validation

`tests/art_smoke.gd` checks all16 atlas frames, transparency, cache reuse, overlay
center, stage progression and unchanged gameplay geometry/stats. Existing native
combat/progression tests still run. Browser checks cover movement through the new
art, actual late-floor encounters, inventory, phone/short-phone/desktop layout
and rendering errors. Visual review on a real iPhone remains valuable.
