# Game design — current working specification

Status: playable ten-floor action roguelite prototype. This is a living design.
[ECONOMY_SPEC.md](ECONOMY_SPEC.md) is the detailed economy/synthesis contract;
[BALANCING.md](BALANCING.md) lists implementation defaults, controls and testing.

## Core loop and platforms

Browser first, PC-download and mobile-adaptable Godot 4.6.3 / GDScript project.
Three-quarter top-down presentation inspired by the camera angle of Archero, with
original placeholder visuals and mechanics. Automatic attacks continue while moving. Six weapon families are playable;
[WEAPONS_SPEC.md](WEAPONS_SPEC.md) defines their attacks and upgrade interactions.

Prepare at the menu hub → start a fresh dungeon → explore/fight/build the character
→ defeat the exit boss → descend through a harder version of the same layout.
Death or completion returns to the hub. The current expedition ends after floor 10;
floor 11+ is not enabled. Saved inventory, coins, gems, keys, parts and perks survive
runs. Run XP levels, card upgrades, health state and flares reset on a new run.

## Map and room identities

- 5 × 5 rooms, coordinates A–E / 1–5. All neighbouring rooms remain connected.
  No doors close, and paths never become walls.
- Generate once per run. Room base identities persist across all floors in that run.
- Start on a random perimeter location. Exit/boss is in the opposite half.
- Start and boss move each floor and temporarily override ordinary room identities.
  They never override bonus rooms. When they move away, the base identity returns.
- Prototype opposite-half rule excludes the middle row/column: top starts use exit
  rows 4–5; bottom starts use 1–2, with equivalent columns. Corners retain their
  generating edge. Both start and boss must move from their previous position.
- Initial start/boss rooms have underlying empty identities; visible ordinary-room
  counts may therefore change after temporary roles move.
- Adjacency constraints beyond connectivity remain a future design task.

| Floor-one room | Count |
| --- | ---: |
| Start | 1 |
| Boss/exit | 1 |
| Bonus: shop, trader, free upgrade, wheel, healer | 5 |
| Combat | 7 |
| Initially empty | 3 |
| Loot | 4 |
| Trap | 4 |
| **Total** | **25** |

### Progression by room

Combat rooms increase encounter strength. Loot rooms are free of defenders on
floor 1, gain defenders and better rewards on floor 2, and grow harder on floor 3.
Floors 5 and 10 loot rooms have a miniboss treasure guardian and improved chest rarity
odds. Later multiples of 5 will continue this milestone pattern.

Initially empty rooms are empty on floors 1–2. On floor 3 they contain weaker,
tier-2 enemies. Floor 4 keeps tier 2; floor 5 uses tier 3. They award their completion flares separately from enemy kills.

Trap rooms retain their identity but never repeat the same trap on consecutive
floors. Current traps are a slow field, timed spikes, and a projectile volley.

The five bonus locations rotate through all five service types, retaining one of
each on every floor and returning to the same service every five floors. Their
first-entrance reward is paid once per room per floor, even if the service is unused.
All floor-specific encounters, stock, rewards and uses refresh on descent.

## Combat, XP and run choices

- Touch: floating joystick anywhere except interface buttons. Keyboard: WASD/arrows.
- Chasers pressure the player. Shooters stop to aim, then fire 1/2/3/3/4-shot
  bursts across floors 1–5, with fan finishes on floors 4–5. Brutes telegraph a
  locked-direction charge, collide with obstacles, and recover without attacking.
- Combat rooms use persistent Mixed/Swarm/Crossfire/Heavy/Ambush variants. Ambushes
  have two waves, with marked arrivals; dormant enemies cannot be hit early or
  bypassed to claim a room completion. Doors remain open throughout.
- Bosses start alone. Floor 1 alternates spread and charge; floor 2 adds warned
  ground zones; floors 3–5 combine spreads with ground zones and gain faster
  recovery below half HP. Future summons may give XP only, never boss-room flares.
- Stats and attack timings are recorded in BALANCING.md. Boss access remains
  immediate: exploring earns upgrades, healing and better loot, rather than keys
  or room-clear quotas to unlock the boss.
- Pillars block both sides' projectiles. Doors remain open for retreat.
- Dead and wounded enemies retain their state across room visits. Bullets do not
  travel across rooms. Brief hit invulnerability and arrival protection apply.
- Enemies drop XP crystals. Nearby unobstructed crystals are attracted to the player;
  uncollected crystals and item pickups remain in their rooms.
- Level-up eases combat from 65% to 15% speed over 0.45 seconds, with player
  protection, then pauses it while choosing. Three Sanctuary jade/gold cards sit
  across the room, with the dungeon still visible behind a light veil. Their
  names, icons and descriptions roll downward, then settle in staggered order.
  The rolling is cosmetic: authoritative offers and reward RNG are unchanged.
  Cards cannot be selected until every choice settles, preventing held-thumb
  selections. Choose one of three distinct eligible upgrades; there is no coin card.
  Excess XP is retained; queued choices remain paused without another slowdown.
  Free/start/shop/wheel/loot choices use the same three-upgrade reveal,
  with no combat slowdown in those presentations. Selection grants once,
  clears the movement stick, and resumes with a short safety window. Glyphs and
  text reflect the current weapon, including the three Meteor alternatives.
- Nine weapons: ranged Bow, Crossbow, Wand, Spear and Chakram; melee Sword,
  Dual Axe, Club and Hammer. New weapons have held art, inventory art and distinct
  attack behavior. Each has three support upgrades and two exclusive signatures.
- Shared upgrades and all weapon interactions follow [WEAPONS_SPEC.md](WEAPONS_SPEC.md)
  and the editable [v2 catalog](design/weapon_upgrades_v2.json). Ranged-only cards
  are Ricochet, Attack through obstacles, Follow and Extra Projectile. Melee-only
  cards are Larger Area, Jump Attack and Hard Slam. Multishot adds consecutive
  attacks for every weapon. The old system is safely archived with a Git tag.
- Loot, room-gold bonuses and direct wheel/shop coin rewards use the persistent
  coin wallet. Upgrade choices never grant currency.
- The permanent Starting upgrade perk gives a choice of three upgrades,
  preventing free currency farming by repeatedly starting and abandoning runs.

## Flares and room services

Flares are temporary per-run currency, retained between floors.

| Source | Flare reward |
| --- | --- |
| Bonus first entrance | 5 on floors 1–5, then +5 per ten-floor band |
| Normal/shooter kill | 1 |
| Brute kill | 2 |
| Loot pickup | 10, or 20 on floors divisible by 5 |
| Initially empty room | 0 on floors 1–2; 5 on floor 3, +1 each later floor |
| Trap room | 0 |
| Boss | 50 on floor 1, +10 per subsequent floor |

Room rewards are once per room per floor. Eligible defenders also pay individual
kill rewards. Boss-room adds never give flares. No revisit resets rewards.

- Healer: full heal once per floor; full-health visits do not consume it.
- Free upgrade: three upgrade cards, once per floor.
- Trader: exchange one owned run-upgrade rank for one of three eligible alternatives,
  once per floor. Nothing is removed until confirmation.
- Wheel: one spin; heal, coins, choose between three upgrades, trade an upgrade for
  one of three, or summon a shopkeeper. No eligible trade gives coins instead.
  Summoning a shopkeeper never repeats the bonus-room entrance reward.
- Dungeon shop: common equipment copies paid with coins; run upgrades/healing/coins
  paid with flares. Finite stock per room per floor. No keys or seals are sold.

## Hub menu and inventory

Full-screen painted tower background and clickable Sanctuary crown. Bottom tabs, exactly:
**Shop → Inventory → Play → Perks → Miscellaneous**. Play selects the home page;
clicking the tower or Enter the Dungeon starts the run. All menus pause gameplay.

Inventory has eight active slots around the central character:
left Weapon/Armor/Headgear/Pants; right Boots/Necklace/Ring/Bracelet.
The owned-item grid is underneath. Each copy has its own identity, level, rarity
and enhancement. Duplicate finds remain separate items, never scrap.
Inventory uses Sanctuary jade, tarnished gold, serif headings and a framed champion
alcove. Swipe directly over items to scroll on mobile, with momentum and no item
activation after a drag. Hover reveals non-modal item details on desktop; tap or
hold reveals them on touch. Equip/level/unequip actions remain in that preview,
which dismisses on pointer departure, an outside tap, scrolling, or tab change.

Two extra squares below the character are reserved and locked. Pet's milestone is
first reaching floor 10 (saved permanently); Spirit unlocks later with its threshold
still undefined. The Pet milestone is tracked, but pet gameplay remains reserved.
Locked squares have no captions: stone covers, crimson metal chains and a lock.
The battlepass banner, player portrait/name, home resource strip and left journal
belong only to Play. Other bottom-tab screens have their own content from the top,
without carrying home controls across. The banner and journal open development placeholders.
Right-side features are reserved. Gems and task rewards await their definitions.

Equipment stats are copied into a new run. Equipping, leveling or synthesizing in
the hub cannot retroactively change the active run. Existing charm saves migrate
to Necklace without losing the item or its level.

## Coins, gems, floor keys, shop and synthesis

**There is no scrap currency or scrap crafting.** Equipment is found in dungeons,
opened from shop chests, or purchased as one of the daily common-item offers.

The hub shop has six daily coin offers: armor/accessory/weapon parts plus three
random common copies. Armor parts level armor/headgear/pants/boots; accessory parts
level bracelet/necklace/ring; weapon parts level weapons. Item levels and rarity
synthesis are separate operations.

The shop keeps its six daily offers above a dedicated Gold chest panel. Gold has
chest art on the left and illustrative legendary item placeholders on the right.
Below it, Copper (left) and Silver (right) have smaller side-by-side panels, with
chest art on the left and opening buttons on the right. Sanctuary jade/gold styling
and swipe scrolling match Inventory; the shop has its own currency readout.

Each chest has Open 1 / Open 10. Spend 1 / 10 matching keys when available;
otherwise spend the full gem amount, keeping any keys below the threshold.
Gem prices: Copper 80 / 720, Silver 150 / 1350, Gold 300 / 2700.
Batches are all-or-nothing and apply pity independently to each roll. All rewards
are shown together within Shop and added to Inventory; opening does not change tabs.
Copper/silver/gold shop chests use matching keys or gems. Exact odds are tuning
values but preserve the requested distribution. Each has a saved, separate
35-open pity mechanic. Gold guarantees Legendary +1 after 34 non-legendary opens;
ANY legendary gold drop, including normal legendary, resets that counter.

Keys come from low-chance dungeon loot and limited daily floor clears. Every floor
has its own allowance of three key-paying clears per day. Floors 1–5 pay copper1,
silver1, copper2, silver2, gold1. Floors 6–9 alternate copper3/silver3; floor10 gold2.
Floors11–14 alternate copper4/silver4; floor15 gold3, continuing thereafter.

Synthesis replaces the character area with a top-left base slot and ingredient
slots. The inventory remains below, grouped by duplicates, highest rarity first.
The exact eight recipes through bright-orange Mythic are in ECONOMY_SPEC.md.
Common now requires three OTHER common copies of the exact same item, matching
Uncommon and Rare identity requirements. Once a base is selected, the inventory
shows only valid ingredient copies. Quick synthesis repeatedly combines eligible
Common/Uncommon/Rare bases, including Rare→Epic, never consuming Epic or higher.
It protects equipped ingredients and prefers equipped/high-level bases.
The base retains its level and equipped identity; additional equipped copies are
protected from consumption. There is no automatic duplicate conversion.

## Permanent perks

All12 slots are defined. First purchase always unlocks Starting upgrade. Further
purchases unlock the other11 randomly, then level eligible non-maxed perks only
after every perk is unlocked. Existing levels are preserved when new slots arrive.
Prices start250 coins, +50 per purchase. Effects are copied into the next run.

| Perk | Effect per level | Cap |
| --- | --- | ---: |
| Starting upgrade | Start with one three-upgrade choice, no coin card |1|
| Starting HP | +1 starting HP |25|
| Dodge | +1 percentage point dodge |25|
| Boss damage | +2% boss/guardian damage |25|
| Recovery | +1% healing received |25|
| Resourcefulness | -0.5% dungeon-shop prices, coins and flares |20|
| Scavenger | +1% dungeon-earned coins, excluding cards/shop payouts |25|
| Collector | +2% XP pickup radius |25|
| Trap resistance | -1% trap damage |20|
| Elite hunter | +0.5% damage to brutes/guardians |20|
| Treasure sense | +0.2 percentage points loot-equipment chance |25|
| Loot gold | +1% coins from loot rooms |25|

Scavenger and Loot gold add together on loot coins. Fractional coin bonuses accrue
within the run instead of rounding every small payout up. Dungeon discounts do
not affect the hub shop, chests, perks or synthesis.

The Perks page uses twelve individually framed Sanctuary cards and one bottom
**Obtain** button, with the current coin cost shown above it. Initially every card
is greyed out, displays a lock and “Locked”, and conceals its perk name/icon.
Unlocked cards display their own icon and name, with one star for every level
across multiple rows when necessary (no star-count abbreviation at level25).
Hover on desktop or tap/hold on mobile shows a non-modal preview of the current
numeric effect, plus the next effect or maximum status; locked cards have no preview.

An unlock presents a large locked card at the centre and flips it to its icon,
name and first star. Its short effect description appears below during the flip.
A level-up presents the existing-star card on the left and a matching one-star
card on the right; both move together, then the centred card shows all new stars
and the updated effect below. The reveal dismisses automatically. The reward is
saved before animation and additional obtains are blocked until it ends.
Insufficient coins or fully capped perks disable Obtain. Navigation or resizing
may dismiss a reveal, but cannot revoke the saved perk or buy another one.
Second Chance is a rare run upgrade, never a permanent perk.

## Saves, migration and deferred work

Device-local atomic JSON/browser storage; no cloud accounts or cross-device sync.
New saves retain item instances, wallet, parts, keys, daily counters, pity, perks,
loadout and highest floor. Old equipment levels/equipped identities are migrated.
Retired prototype scrap, generic keys, seals and training are archived without
inventing an exchange rate. Current-run state is not saved.

Future: defined gem tasks/earning, higher floors,
melee-specific upgrades, further rarities, pets/spirit content, more item templates/affixes, adjacency
constraints, final art/audio, richer combat and an authoritative account backend.

## Current item roles, reset and future checkpoints

Necklace, armor, headgear, pants and boots grant HP. Armor also reduces incoming
damage. Ring increases critical DAMAGE rather than chance. Bracelet adds damage
alongside its attack-speed bonus. Exact level/rarity values and modest enemy HP
increases are in BALANCING.md. Rooms have about16% more playable area.
Shop Epic/Legendary odds are reduced while35-open guarantees remain. Loot-room
item drops are no longer guaranteed; non-equipment chest rewards remain.
Reset everything in Cheats asks for confirmation, then starts a fresh local
profile with its starter bow and no currencies, perks, counters or progress.

Planned checkpoint starts: floors10,20,etc, once their milestone is unlocked.
This will let stronger accounts begin deeper without inflating early-floor HP to
match late-game damage. Unlock details/starting bonuses remain to define; the
checkpoint selection is not implemented yet.

## Shared power budget

Current damage/attack-speed stacking and all attack delivery use the shared
contract in [POWER_BALANCE.md](POWER_BALANCE.md). Extra projectiles and sequential
shots still increase count, but share a bounded damage budget; overlapping splash
and meteor impacts cannot multiply repeatedly against the same victim in one
attack cycle. Floors1–2 stay forgiving, with a stronger health step from floor3.
New weapons/upgrades/perks must be checked against the repeatable scenarios and
live mobile testing before treating their tuning as balanced.

## Utility cards and ten-floor expansion

Vitality grants10% starting maxHP per rank, healing the HP gained. Full Heal
restores all missing HP. Lifesteal is damage-based with cycle/second limits.
Reach improves projectile speed or melee reach. Room Barrier blocks one hit per
room with no time limit; revisiting never replenishes a spent block. Room Gold
pays3 coins per rank once per completed non-start room, per floor.
Second Chance is rare and revives immediately at25% maxHP once per run.
Gatherer, Last Enemy, Momentum and Stop and Aim are retired from the offer pool.
All caps, weapon cards and signature replacements are documented in
[the v2 specification](design/WEAPONS_V2.md). The animated reveal remains in use.

Progression now ends after floor10. Floors6–10 have stronger tiered encounters;
combat counts cap8, loot defenders cap4 except guardians on5/10, empty enemies
stay lower-tier. Brute HP is reduced15% and boss/guardian HP20%; later-floor
values are tuning defaults documented in BALANCING.md. Floor10 pays2 gold keys
per eligible clear (first3 clears/day), and records the pet milestone without
implementing pet gameplay. Checkpoint selection remains a separate planned feature.

## Approved visual direction and first production pack

Original illustrated three-quarter dark fantasy. Launch art plan: five ten-floor
regions through50, expandable toward100 and other game modes. Fallen Sanctuary
(1–10), Crimson Court(11–20), Ashen Foundries(21–30), Living Depths(31–40), Hollow
Throne(41–50). Architecture/materials evolve; deeper does not simply mean darker.
[ART_DIRECTION.md](ART_DIRECTION.md) records approved references, assets and scope.

Floors1–10 now use Sanctuary production textures, transparent hero/enemy/prop
atlases, depth sorting, chest state artwork and gradual border corruption. Future
region references are archived, not playable production packs. Six architectural room templates now have matching collision/navigation and connected door routes.
Heroes and regular enemies have movement/attack frames. Weapons are visible and
animate per type; inventory uses a frontal portrait holding the equipped weapon.
Each floor has a distinct boss silhouette/name/attack rotation (see ART_DIRECTION.md).
Boss windup/lunge animation currently uses anchored sprite transforms. Player
damage, enemy HP and rewards remain unchanged. Additional directional/boss/death
frames, armor cosmetics, remaining icons, later biome packs and final audio remain.

## Architectural room templates

Rooms now use six authored structural plans: Processional Hall, Jade Sluice,
Fractured Crypt, Collapsed Cloister, Lava Aqueduct and Sunken Courtyard.
Canals/ruptures are unwalkable ground; stone bridges and surviving walkways
connect the reachable floor. Canal sources and drains are built into walls.
Props are arranged around the architecture with purposeful paired placements.
Layouts persist across floors as before; room roles continue to rotate separately.
All doors and central interactions must connect to the entire walkable room.
Ground enemies and charges respect gaps and crossings. Projectiles pass over gaps,
while solid scenery remains cover. Gaps are movement barriers with no contact damage
in this pass. Rendering and navigation share the same authored terrain definitions.
See ART_DIRECTION.md for each plan and validation details.

## Player animation rebuild and next milestone

The inventory uses six complete painted weapon-holding portraits, one per weapon
type. Hands, bent arms and held equipment are part of each complete pose.
In-game locomotion uses a continuous jointed cutout rig with a distance-driven
stride, fixed body-part dimensions, blended start/stop and stable facing changes.
Arms use two-link inverse kinematics with gripping hands drawn over weapon handles.
Weapon preparation/release/recovery is layered over walking instead of replacing
the whole body. Extra shots cannot reset the leg cycle. Bow draw/string release,
crossbow recoil, sword sweep, hammer wind-up/slam, wand casting/laser hold and
chakram throwing have different arm motions. Actual releases drive the animation;
visual projectile launch positions start at the held weapon.

**Reminder after the in-game animation pass:** rename and rework the item lineup,
create sprites for all items, then work on the menus and home GUI. This is the
next requested milestone; item icons/menu redesign have not been started here.

## Projectile and attack VFX pass

All weapon attacks now use animated painted effects: arrows and heavy bolts,
magic lances and rune lasers, blade-ribbon slashes, erupting-stone hammer waves,
spinning bladed chakrams, falling/rolling meteors, fiery explosions and hit sparks.
Explosion art progresses through ignition, blast/debris, smoke and embers.

Render density is bounded independently of damage simulation. Overlapping blasts
can share one visual; meteor/rock sprites are spatially sampled under heavy load.
Every impact still applies its existing damage budget. Rolling meteor collision
uses swept segments and cached eligible enemies per cycle, including reinforcements
when they activate. Performance and damage-preservation checks are documented in
ART_DIRECTION.md. The next item rename/rework, all item sprites and menus/home GUI
milestone remains queued after attack-animation tweaks.

## Complete Sanctuary room backgrounds

The 5×5 dungeon uses ten complete painted room environments, stable per room
across floors: Quiet Sanctuary, Weathered Flagstones, Broken Corners, Split Crypt,
Jade Waterway, Molten Aqueduct, Drowned Court, Ruined Cloister, Twin Watercourses
and Ember Crossing. Floors, terrain cuts, bridges, walls and fixed scenery are
painted together. Cracks are part of the slabs; holes show floor depth; channels
have built-in wall outlets, banks and crossings. Separate static pillar sprites,
crack overlays and modular wall assembly are removed from the renderer.

Collision is traced to each finished image. Bodies cannot cross holes, water or
lava, while projectiles can; low masonry blocks both. Doorways are recessed into
the perimeter walls. Existing neighboring rooms illuminate the painted recesses;
no freestanding side-door object is drawn. Backgrounds are cached single quads.
The ten paintings currently represent the Sanctuary, not future region artwork.
See ART_DIRECTION.md and ROOM_REFERENCES.md for the room list and validation.

## Tower home, player windows and champion identity

The home/Play page uses a complete painted tower scene. Its crown matches the
Fallen Sanctuary: ivory arches, jade roofing and tarnished gold. A visible lower
stretch becomes burgundy, scorched stone and molten infernal light. The tower
and the Enter the Dungeon button both start an expedition. The right side remains
available for future features. The existing five bottom tabs keep their order
and now use original painted icons and jade/bronze button styling.

A volcanic banner at the top opens an overlay saying “Hell in development”.
It reserves the battlepass; it has no purchase or reward behavior yet.
The upper-left champion portrait opens a dropdown with Settings, Bag and Details.
Clicking outside the dropdown/window or closing a window returns to the same page.

- Settings: master, music and effects volume plus mute. Preferences persist in the
  existing local profile and apply to the Master/Music/SFX buses. Audio tracks
  and effects are not yet implemented. An editable Insert Code area is present;
  redemption is explicitly unavailable and never grants currency/items.
- Bag: a separate event-belongings window reserved for shards, event currencies
  and special containers. It is currently empty; equipment stays in Inventory.
- Details/Chronicle: best floor, save/progression information, game version,
  development status, current UTC date/time, engine attribution and copyright.
  Full engine/third-party/font license notices are available in a scrollable view.
- A left parchment journal holds Daily Tasks, Daily Login, Privileges and Event.
  All four open clearly marked development placeholders; rewards are undefined.
- Miscellaneous keeps the cheat menu. Progression/build information moved to
  Details. Existing cheats and the dungeon economy remain unchanged.

Default champion (working name): **Aster, the mortal-born**. An unhooded human
hero with short dark hair, a visible face, bronze sun cuirass, ivory sash, warm
skin, crimson cloak and bronze greaves. He appears consistently in the profile,
all six complete weapon-holding inventory poses, and the existing continuous
in-game animation rig. No stats or abilities change with this visual revision.

Future champions will reference gods from different mythologies: Hades, Zeus,
Hou Yi, Chang’e, Baron Samedi, Ullr, Thor, Tsukuyomi and Amaterasu. These are future
roster directions, not implemented characters or selectable powers yet.
Room artwork remains provisional pending the designer's laptop sketches.

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

## Experimental shared animation lab

An isolated lab under Miscellaneous tests one editable Skeleton2D rig, weighted
arm meshes, shared AnimationPlayer clips, two compatible humanoid skins, two bow
designs and a hammer. Equipment uses editable attachment profiles and moving bow
strings. Walking and upper-body actions are independent; inspection, pause and
scrubbing controls are available. Side view is the reference. Front/back fitting
and weapon perspective remain provisional. This experiment does not replace the
dungeon renderer or unlock a second champion. See prototypes/animation_lab/README.md
for source scenes, resource editing and the artwork contract.


## Separate room-layout sandbox

The current ten-floor dungeon remains the comparison build. An independent
Room Lab is available from Miscellaneous or `?room_lab=1`. It tests 1568×1904
worlds with a following camera, connected courts, branching paths and bridges,
using Hades-style spatial ideas rather than reproducing its maps or artwork.
The routes themselves define the floor; void is non-walkable and low scenery
blocks projectiles. Projectiles can cross open gaps. Every court, shrine and exit
has a validated path with body-radius clearance.

Three editable plans: Processional Steps (two-sided loop), Broken Forum
(split galleries and cross-link), and Cinder Causeways (islands over lava).
Each has four spatially activated packs:24 enemies normally or36 in crowded mode.
Existing melee/ranged enemy behaviors and all nine weapons are reused. The
sandbox has a fixed temporary loadout, local XP/upgrades, optional invincibility,
a once-only healing shrine and a clear-all-packs exit. No account rewards,
spending or loadout changes are saved. Map view pauses combat; restarting,
changing layout or changing weapon resets the temporary encounter.

This is a layout/combat-flow prototype, not final environment art or a replacement
for dungeon generation. Floor plans and collision live under
`prototypes/room_lab`; the main room-layout catalog is unchanged.

## Separate 3D view/style experiment

A third lab, under `prototypes/isometric_lab`, tests a true3D scene with a fixed
orthographic camera,45° yaw and selectable50°/35.264° inclination. It is available
through Miscellaneous → 3D view lab or `?iso_lab=1`. The open Sanctuary test scene
uses modeled platforms, ivory/bronze architecture, jade stone, crimson cloth,
actual shadows, a bridge and a raised terrace with stairs.

The temporary hero uses reusable limb pivots and a physical hand attachment for
sword/spear meshes, walking/cape poses, a simple attack and dash. Three targets
start sparring only after the player attacks. Controls are screen-relative with
floating-stick/two-finger mobile input. Overview pauses the test; Reset restores
its targets and health; a lighter shadow-free mode is available.

The experiment has no account progression, currency rewards or equipment writes.
Existing gameplay/art and both older labs remain intact. These are provisional
low-poly models for judging the view, scale, movement and atmosphere, not final
art or a decision to convert the whole game. Production character rigs/assets
and native iPhone performance remain to evaluate after this test.
