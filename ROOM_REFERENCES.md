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

## Current implementation: complete environments

The modular-wall/material pass was superseded following visual testing. Each of
the ten production images in `art/rooms/` is a complete room painting, not a floor
texture with crack and prop sprites layered over it. Paving joints, chipped slabs,
collapsed edges, channels, banks, bridges, wall vents, fixed ruins and their
shadows are painted together. The shared Sanctuary architecture uses continuous
walls with door apertures cut through the perimeter, including left and right.

The catalog is `scripts/room_backgrounds.gd`; `room_backdrop.gd` draws one cached
quad. `room_doors.gdshader` lights the existing recesses for valid neighboring
rooms. No other static geometry, liquid overlay or pillar sprite is drawn.
Collision in `room_layouts.gd` is calibrated to the final paintings. Full-room
textures are image-generated original art; original outputs are preserved.

All ten templates are used across a seeded 5×5 map and remain stable as the
player descends. The sets represent floors 1–10 (Sanctuary); later regions remain
future production work. Terrain currently blocks movement without dealing damage.

Architecture tests verify connected walkable areas, all doors/reward positions,
projectile cover, bridge necessity, enemy pathing and safe spawn projection.
All-room smoke tests check transitions; `browser_architecture.py` captures all ten
at mobile dimensions and tests the actual canal/bridge crossing. Backdrop tests
cover unique textures, template coverage, exit lighting and draw caching.
