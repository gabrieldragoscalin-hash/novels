# Sanctuary room construction reference pass

## Reference inspected

Original Archero gameplay capture (cropped upper-room view), community-hosted:
https://github.com/dqle/Archero-Farmer/blob/master/tmp/check_stage3end.png

The image shows a substantial back-wall face, a recessed illuminated doorway,
large quiet floor slabs and low cover blocks with visible top/front faces.
The App Store, Google Play and attachment-CDN pages were inaccessible from the
cloud network. The directly hosted gameplay capture above was visually inspected.
No code from the community project is used, and its screenshot is not shipped as
a production game texture.

## Design decisions

- Keep the original Fallen Sanctuary palette and painted ivory/jade/gold materials.
- Give back walls visible height and inward-facing side entrances.
- Use coherent low-cover groups instead of relying on tall decorative pillars.
- Use one consistent floor/cover scale and quieter paving with no universal octagon.
- Replace flat water/lava stripes and bridge diagrams with painted materials,
  recessed bank faces, textured crossing decks, and wall outlets/drains.
- Keep room-specific compositions: ceremonial cover islands, sluice banks, paired
  crypt monuments, collapsed quadrants, aqueduct cover lanes and courtyard pools.
- Cache static floor, walls, banks and decks in a background CanvasItem; animate
  the liquid surface separately. Doorways follow the actual neighboring rooms.
- Compact the dungeon header enough to leave room for the raised back wall.

## Implementation and validation

New original assets: arena_floor.png, masonry.png and surfaces.png.
Room data: scripts/room_layouts.gd. Static rendering: room_backdrop.gd and
room_architecture.gd. Repeated materials: room_surfaces.gd.

Masonry is imported with tight alpha bounds; material tiles use inset atlas UVs
and clipped tile edges. Original image-generation outputs are preserved intact.

The play footprint, cardinal doorway locations and run rules remain in the same
coordinate system. New cover footprints participate in both navigation and cover
checks. Existing connected-floor/bridge tests and all-room transition tests apply.
The browser gallery checks each template and walking across the sluice bridge;
arena_style_smoke checks assets, cover collision and static-draw cache behavior.
