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
- Level-up pauses combat and movement. Choose one of two distinct upgrades or a
  persistent coin reward. Excess XP is retained and additional choices queue.
- Shared cards: damage, attack speed, movement, EXP gain, Punchthrough, Extra
  projectile, Multiple Shots, enemy Ricochet, Follow and See All. Extra projectile
  fires parallel ranged/chakram shots, alternating sword slashes, or wider hammer
  cones. Multiple Shots adds sequential attacks within each attack cycle.
- Bow/crossbow cards: Arrow split, Stop and Aim, Explosive arrows. Split and
  Explosive replace one another; Stop and Aim charges while stationary, releases
  on movement or after three seconds, doubles damage and always penetrates.
- Wand cards: Perpetuum continuous laser or Magic Meteor, replacing one another.
  Meteor converts Punchthrough/Ricochet/Follow into Size/Rain/Telekinesis.
- See All passes through obstacles, is never offered to wands, and never reappears
  after selection in that run. Wands pass through obstacles inherently.
- All attack forms, exact interactions and test tuning are recorded in
  [WEAPONS_SPEC.md](WEAPONS_SPEC.md). Old status/healing/critical/magnet/regen cards
  are retired. No additional melee-specific cards are designed yet.
- Coin choices, loot and wheel coin rewards use the persistent coin wallet.
- The permanent Starting upgrade perk gives two upgrades without a coin option,
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
- Free upgrade: two upgrade cards plus a coin card, once per floor.
- Trader: exchange one owned run-upgrade rank for one of three eligible alternatives,
  once per floor. Nothing is removed until confirmation.
- Wheel: one spin; heal, coins, choose between two upgrades, trade an upgrade for
  one of three, or summon a shopkeeper. No eligible trade gives coins instead.
  Summoning a shopkeeper never repeats the bonus-room entrance reward.
- Dungeon shop: common equipment copies paid with coins; run upgrades/healing/coins
  paid with flares. Finite stock per room per floor. No keys or seals are sold.

## Hub menu and inventory

Full-screen original background and central dungeon doodle. Bottom tabs, exactly:
**Shop → Inventory → Play → Perks → Miscellaneous**. Play selects the home page;
clicking the dungeon icon starts the run. All menus pause gameplay.

Inventory has eight active slots around the central character:
left Weapon/Armor/Headgear/Pants; right Boots/Necklace/Ring/Bracelet.
The owned-item grid is underneath. Each copy has its own identity, level, rarity
and enhancement. Duplicate finds remain separate items, never scrap.

Two extra squares below the character are reserved and locked. Pet's milestone is
first reaching floor 10 (saved permanently); Spirit unlocks later with its threshold
still undefined. The Pet milestone is tracked, but pet gameplay remains reserved.
Left-side events/battle pass and right-side daily/play-time rewards are deferred.
Gems and tasks are also reserved until the user defines them.

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
| Starting upgrade | Start with one two-upgrade choice, no coin card |1|
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
not affect the hub shop, chests, perks or synthesis. Tap perk cards for effects.
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

Vitality:+10% starting maxHP per rank (cap5), healing only the HP gained.
Field medicine:restore15% maxHP immediately, repeatable, hidden at full HP.
Gatherer:+25% pickup radius per rank (cap3). Long reach:+10% projectile speed or
+5% melee reach per rank (cap3); lasers gain beam width and meteors fall/roll faster.
Last enemy:+15% damage per rank when one enemy remains (cap2).
Momentum:clear combat for+10% movement in the next room (cap1).
Emergency barrier:block one hit during the first4s of a hostile room (cap1).
Salvage:+3 coins per combat clear per rank (cap3).
Second Chance:rare, cap1, instantly revive at exactly25% maxHP once per run.
It never reappears after selection/consumption and cannot be traded. A1.5s grace
window prevents the same impact from immediately killing the revived player.

Most choices pair offense with defense/utility, plus coins. Defining cards use
relative weight0.35, ordinary cards1, Second Chance0.08. Declined form-switch
cards have reduced repeat weight. These are relative weights, not fixed odds.
Barriers never refresh on revisits; Salvage/Momentum require a first combat clear.
Instant Field medicine cannot be traded after its healing is consumed.

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
