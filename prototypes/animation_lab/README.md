# Shared character/weapon animation proof

Open `lab.tscn` with F6, or use **Miscellaneous → Animation lab** in the browser.
Direct browser route: `?animation_lab=1`.

This is an isolated experiment. It does not replace `scripts/hero_animation.gd`
or change combat, equipment, champion unlocks, or account data. The second skin
is a fitting example, not a playable champion. Side view is the visual reference;
front/back fitting checks still reuse flat weapon artwork and need directional
weapon art before production use. Mechanical grip accuracy does not establish
that an illustration or pose looks finished.

## What is shared

- One `Skeleton2D` / `Bone2D` hierarchy, persisted as a normal editable scene.
- Weighted `Polygon2D` upper/lower arm meshes, including shoulder overlap.
- One external `AnimationLibrary`: bow and hammer actions in three views.
- A separate walking library, independent of the upper-body action.
- Both skins use exactly the same animations and bone lengths.
- Both bows use exactly the same bow clips. Only their profiles differ.
- Authored main-arm/weapon motion and baked support-arm curves. Runtime support
  correction adapts grip variation without rebuilding the entire body pose.
- Left-facing art is mirrored from the side rig. Bowstrings render independently
  from the equipment sprite, under the gripping fingers.

## Files to edit in Godot

1. Open `generated/shared_champion.tscn`. Its tool script previews the exported
   `skin`, `weapon_id`, and `view` options in the editor.
2. Select **AnimationPlayer** and choose a clip in `generated/motions.tres`.
   Edit the arm bones and `MainHand/WeaponSocket` keys through the Animation panel.
   The support arm has baked curves plus a contact correction while running.
3. The **WalkPlayer** controls legs and body bob independently.
4. Select `Skeleton/MainUpperMesh` or another arm mesh to inspect its polygon,
   UV coordinates and bone weights. Attachment origins and the rest pose must stay
   compatible across skins.
5. Open `generated/sun_bow.tres`, `moon_bow.tres`, or `hammer.tres` to adjust the
   actual texture, rendered size, normalized grip, string tips or support point.
   No champion-specific animation is stored in these weapon resources.

Godot edits to these `.tscn` / `.tres` files are valid source edits. The build tools
below regenerate the starting templates and **overwrite those files**; do not run
them over manual animation work you intend to keep.

## Artwork contract

A compatible humanoid skin supplies front/back/side head, armless torso, upper
arm, forearm, gripping hand, thigh, shin and cape parts. Each skin is fitted once
to the common rest pose. The current atlases are 4 columns × 6 rows; closed hands
have their own 3 × 2 atlas. UV metadata is generated without modifying pixels.

A weapon design supplies its real sprite, correct orientation, handle anchor,
and family-specific contacts. Bows must be unstrung: the rig draws the moving
string. Extra directional weapon views remain necessary where one flat sprite
cannot represent the perspective. A new weapon family needs its own clips once;
a new design within a family should only require an attachment profile. Different
humanoid proportions need fitting; non-humanoid bodies may require another rig.

The new artwork is test material. Anatomical posing, joins, foreshortening and
front/back weapon projection still require visual review; the lab is deliberately
not promoted to the dungeon renderer automatically.

## Regenerate the initial templates

Run from the project root after importing assets:

```
godot --headless --path . --script tools/build_animation_lab_atlas.gd
godot --headless --path . --script tools/build_animation_lab_profiles.gd
godot --headless --path . --script tools/build_animation_lab_rig.gd
```

`tests/animation_lab_smoke.gd` checks both skins over 101 phases, three weapons and
four directions: shared libraries, matching main-arm motion, and support contact.
The green markers are attachment diagnostics, not a judgement of the artwork.
