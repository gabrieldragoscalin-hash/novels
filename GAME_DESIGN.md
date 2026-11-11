# Game design — current working specification

Status: playable five-floor action roguelite prototype. This is a living design.
[ECONOMY_SPEC.md](ECONOMY_SPEC.md) is the detailed economy/synthesis contract;
[BALANCING.md](BALANCING.md) lists implementation defaults, controls and testing.

## Core loop and platforms

Browser first, PC-download and mobile-adaptable Godot 4.6.3 / GDScript project.
Three-quarter top-down presentation inspired by the camera angle of Archero, with
original placeholder visuals and mechanics. Automatic attacks continue while moving. Six weapon families are playable;
[WEAPONS_SPEC.md](WEAPONS_SPEC.md) defines their attacks and upgrade interactions.

Prepare at the menu hub → start a fresh dungeon → explore/fight/build the character
→ defeat the exit boss → descend through a harder version of the same layout.
Death or completion returns to the hub. The current expedition ends after floor 5;
floor 6+ is not enabled. Saved inventory, coins, gems, keys, parts and perks survive
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
Floor 5 loot rooms have a miniboss treasure guardian and improved chest rarity
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
| Bonus first entrance | 5 on floors 1–5, then +5 per five-floor band |
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
still undefined. The current floor-5 cap makes Pet inaccessible for now.
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

Twelve slots. Four defined perks: Starting upgrade (one level), Starting HP,
Dodge chance and Boss damage (25 levels each). Eight slots remain reserved.
First purchase always unlocks Starting upgrade at level 1. Other locked perks
unlock randomly at level 1. Per the user clarification, leveling begins after
ALL FOUR DEFINED perks unlock; reserved slots do not block it. Further purchases
randomly level eligible non-maxed perks. Maxed perks cannot be drawn.
Prices start at 250 coins and increase each purchase; the current +50 increment
and per-level effects are prototype tuning values documented in BALANCING.md.

## Saves, migration and deferred work

Device-local atomic JSON/browser storage; no cloud accounts or cross-device sync.
New saves retain item instances, wallet, parts, keys, daily counters, pity, perks,
loadout and highest floor. Old equipment levels/equipped identities are migrated.
Retired prototype scrap, generic keys, seals and training are archived without
inventing an exchange rate. Current-run state is not saved.

Future: defined gem tasks/earning, the remaining eight perk effects, higher floors,
melee-specific upgrades, further rarities, pets/spirit content, more item templates/affixes, adjacency
constraints, final art/audio, richer combat and an authoritative account backend.
