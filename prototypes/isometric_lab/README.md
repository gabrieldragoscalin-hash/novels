# 3D view lab — The Veiled Sanctum

Open **Miscellaneous → 3D view lab**, use `?iso_lab=1`, launch Godot with
`-- --iso-lab`, or open `lab.tscn` and press F6.

This is a separate, real 3D camera/style experiment. The existing game, room lab,
and animation lab remain available. There is no account wallet, inventory,
progression or saved reward in this scene.

## What to judge

- A fixed diagonal orthographic camera with a following view and a full overview.
  The Angle button compares 50° and the classic 35.264° isometric inclination;
  yaw stays 45°. Movement follows screen directions at either angle.
- An enclosed underworld hall with monumental carved rear walls, recessed oracle
  reliefs, large damaged pillars, a genuine central pit, urns, sarcophagi and
  warm yellow candlelight. Near walls are cut away for camera visibility. Painted
  stone/frieze/relief materials and ink outlines replace the flat pastel slabs.
  Ivory walls, cooler gray paving and muted gold details separate vertical and
  walkable surfaces. Soft diffuse lighting retains carving detail at both angles.
  Horizontal caps use stone paving, not stretched vertical-wall textures.
- The character's weapon is attached to a hand pivot. Sword and spear reuse the
  same character body, walking cycle and attachment; the weapon meshes differ.
- Walking, cape motion, a basic melee swing, dash, three sparring targets and a
  staircase/bridge to explore. This is a view/movement test, not a balance pass.

The room uses an original AI-assisted four-panel painted atlas, with world-space
stone mapping and preserved panel UVs through static batching. The character
models remain provisional. They show
perspective, scale, silhouettes and animation attachments; they are not a claim
of finished Hades-quality artwork. Authored models, textures and production
Skeleton3D animation can replace them after choosing the visual direction.

## Controls

Drag anywhere in the scene to start a floating movement stick. A second finger
can hold Attack or tap Dash while the first continues moving. On desktop use
WASD/arrows, J to attack, Space to dash, or mouse dragging/buttons.

The shades wait while you explore; your first attack starts sparring. Reset
restores your six HP and all three targets. There are no saved rewards.
Overview pauses movement/combat. The light button toggles real-time shadows off
for a lighter rendering path. Hub returns to the regular game and clears the
prototype URL parameters.

## Implementation and checks

`models.gd` constructs reusable material/mesh pieces, character pivots, held
weapons and animation poses. `stage.gd` owns platform geometry, footprints,
obstacles, the central pit, wall openings and stair height. `lab.gd` owns the
isolated SubViewport/World3D,
Camera3D, lights, controls and small combat test.

Static scenery is merged by material to reduce draw calls. The renderer stays
Godot GL Compatibility/WebGL2, with one shadow-casting light,
no imported models, no particles/GI/SSAO, and no changes to the game's 2D renderer.
Actual iPhone performance and final art direction still need human playtesting;
a phone-sized Chromium test does not establish Safari/device performance.

`tests/isometric_lab_smoke.gd` checks camera-relative movement, boundaries,
platform/stair access, attached weapons, cooldowns, damage and reset.
`tests/browser_isometric_lab.py` checks real web rendering, two-finger controls,
angles, overview, weapons, lighting, hub return and unchanged saved account data
on phone/compact/desktop sizes. `?iso_lab=1&iso_probe=1` enables a read-only test
snapshot; it is not an interface for editing gameplay or saves.


The attached Hades reference informed scale, composition, dark stone, inked
contours and green lighting. Its screenshot/assets were not copied. Original
texture source: `art/isometric/underworld_atlas.png` (floor, wall, oracle relief,
floor medallion in equal quadrants). `paint.gd`, `stone.gdshader` and
`ink.gdshader` own the material mapping and outlines. Pit collision and a
body-clearance flood fill protect routes around the well and to both exits.
