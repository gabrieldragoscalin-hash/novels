# Room lab

Open `?room_lab=1` in the browser, choose Miscellaneous → Room lab, run the scene
`prototypes/room_lab/lab.tscn` in Godot, or launch with `-- --room-lab`.

This is an isolated encounter sandbox; it never constructs a Hub or writes account
rewards. Entering/exiting through the normal game can load/refresh the usual hub
save, but the lab itself has no wallet, equipment persistence or milestone rewards.

- Drag anywhere in the play area to move; a fresh floating stick begins at each
  finger position. WASD/arrows and mouse dragging work on desktop.
- Map pauses the fight and shows the full floor plan, room names and remaining
  packs. Resume returns to the following camera.
- Previous/next switches between three plans. Changing plan, weapon or mob count,
  or pressing Restart, resets the temporary fight and upgrades.
- Mobs toggles24/36 enemies, divided into four packs. Packs activate by entering
  their court, not by the old wave timer. Cleared packs never respawn in that test.
- Invincibility is optional. The green shrine heals50% max HP once. Clear every
  pack, then reach the gold exit. Defeat/completion freezes the test until restart.
- 3 upgrades opens a three-card sandbox choice. Combat XP uses the same choice.
  The Hub button stays usable even during the upgrade reveal.

## Editing

`layouts.gd` defines courts, chamfered corners, bridge cells, cover footprints,
spawn centers, shrine and exit. Those cells are the authoritative walkable floor.
`combat.gd` adapts the existing combat engine to those cells and spatial packs.
`floor.gd` caches stone textures, inlaid courts, rim geometry and cliff faces from
that plan; `actors.gd` draws the existing actors and anchored scenery. `lab.gd`
owns the temporary encounter, camera, UI, input and upgrade reveal.

The world is1568×1904. This is over14 times the bounding area of the current
464×438 room; actual traversable area is smaller because much of the world is
void. It is intentionally a topology/playability experiment, not final art.
The main dungeon layouts and population are unchanged.

Tests: `tests/room_lab_smoke.gd` validates paths, body clearance, spawning,
activation, temporary upgrades and currency isolation. `tests/browser_room_lab.py`
checks phone/compact/desktop rendering and input against an actual web export.
`?room_lab=1&lab_probe=1` exposes an opt-in read-only browser test snapshot, not a
command or save-editing interface. Do not use that snapshot as gameplay state.
