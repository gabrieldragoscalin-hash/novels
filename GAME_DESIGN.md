# Game Design — Working Document

Last updated: 2026-11-10

Status: three-floor ranged prototype with a persistent eight-slot inventory and expanded run upgrades. See BALANCING.md for implemented defaults and remaining scope.
No final title has been selected. The prototype uses Godot 4.6.3 with GDScript. Open decisions below must not be treated as
settled requirements. This game replaces the earlier book project in this repository.

## Vision and platforms

A roguelite in which the player learns a dungeon's geography while its rooms
evolve across increasingly difficult floors. Changing starting and boss positions
creates new journeys through a familiar layout. The player aims to reach higher
floors, then returns to a hub after death to use retained loot for progression.

The game should feel familiar but have its own identity, rather than copy an
existing survivor, mobile action, or dungeon game.

Intended platforms: playable in a browser, downloadable on PC, and adaptable to
mobile. Development should begin with mostly free tools and minimal operating
costs. Store releases and monetization are undecided.

## Terms and core loop

- **Room:** one cell in the dungeon grid, containing its own encounter or service.
- **Floor:** one traversal from the starting room to defeating the exit boss.
- **Run:** the attempt spanning multiple floors, ending on death.
- **Hub:** the location outside runs where retained loot supports progression.

1. Prepare at the hub.
2. Start a run and randomly generate a dungeon.
3. Explore rooms, gain XP, choose upgrades, and gather resources.
4. Defeat the exit boss to advance to the next floor.
5. Retain the same dungeon layout and underlying room identities, but change the
   start and exit positions and update floor-dependent contents.
6. Repeat until death.
7. Return to the hub and use retained loot. The next run generates a fresh dungeon.

Prototype: equipment, scrap, keys, supply seals, and hub training survive death in device-local storage. Run XP, levels, upgrades, coins, and flares reset on the next expedition; stored equipment and its levels do not. These defaults can be balanced or revised.

## Dungeon structure

- Grid: **5 × 5**, with coordinates **A–E** and **1–5**.
- All rooms remain accessible. **No doors close and no paths turn into walls.**
- The dungeon's room layout and base identities persist between floors in a run.
- A new run generates a new random layout.
- Room adjacency/generation constraints will be designed later.
- Movement between neighbouring rooms is understood as orthogonal; movement uses a floating joystick or keyboard, with a three-quarter top-down camera and automatic ranged attacks while moving.

### Starting floor composition

| Role/type | Count |
| --- | ---: |
| Start | 1 |
| Boss / exit | 1 |
| Bonus rooms: one of each of the five services | 5 |
| Combat rooms | 7 |
| Initially empty rooms | 3 |
| Loot rooms | 4 |
| Trap rooms | 4 |
| **Total** | **25** |

These are the agreed starting counts. Because start and exit are temporary roles,
the visible counts of ordinary room types can change on subsequent floors.

### Start and boss placement

- The starting room is randomly selected on an outside edge of the grid.
- Its position changes between floors.
- The exit is randomly placed in the opposite half of the grid relative to the
  selected starting edge: top start → lower half; bottom → upper half;
  left → right half; right → left half.
- Every exit room contains a boss.
- Start and exit are **temporary roles overriding a room's base identity**.
  When the role moves away, that base identity becomes active again.
- **Neither start nor exit may override a bonus room.** All five services must
  remain present on every floor.
- Presence of all five services is required; visiting every service is not an
  established requirement for reaching the boss.

Generation defaults now implemented (subject to revision):

- The middle row/column is excluded from opposite-half destinations; top starts use rows 4–5, bottom starts use rows 1–2, with the equivalent rule for columns.
- Corners use their selected generating edge; the opposite-half rule provides separation.
- Both start and exit must move from their previous positions.
- Initial start and boss locations have underlying empty identities. Their temporary overrides move away on subsequent floors.

## Room identities and floor progression

### Combat rooms

Remain combat rooms, with increasing encounter difficulty across floors. Prototype normal, shooter, and brute archetypes, floor counts, and HP scaling are listed in BALANCING.md. Final balance remains open.

Enemies award XP and dungeon flares. Ordinary revisits must not reset rewards.

### Loot rooms

- Floor 1: free loot, with no defending enemies.
- Floor 2 onward: better loot and enemies defending it.
- Floors 3–4 continue increasing rewards and changing encounters.
- Every fifth floor (5, 10, 15, …): miniboss protection and improved loot.
- Floors between these milestones increase enemy levels/numbers and rewards.
- A room remains a loot room across floors unless temporarily overridden by S/E.
- Loot may mean currency, an item, a chest, or a trapped reward; it does not imply
  one specific reward format. Dedicated trap rooms remain a separate category.

### Initially empty rooms

- Floors 1–2: empty.
- Floor 3 onward: contain weaker enemies rather than keeping pace with normal
  combat rooms. The examples given were floor-2 enemies on both floors 3 and 4.
- The general enemy-scaling formula beyond those examples is undecided.
- These rooms retain their underlying category for their distinct progression and
  flare rewards even after they acquire enemies.

### Trap rooms

- Remain trap rooms.
- Change trap type every floor: no identical trap on consecutive floors.
- Earlier traps can recur after an intervening floor, e.g. debuff A → trap B → debuff A.
- Prototype traps are a slowing field, timed spikes, and a projectile volley; timings and counterplay are listed in BALANCING.md.

### Bonus rooms

Five permanent bonus-room locations, with these five service roles:

1. Shop.
2. Trader.
3. Free upgrade.
4. Spin-the-wheel room.
5. Healer.

Each location cycles through all five roles before repeating, returning to the
same role every five floors. Every floor must contain one of each service.
The prototype rotation is shop → trader → upgrade → wheel → healer, staggered across the five locations so no service is missing or duplicated.

#### Free upgrade

Choose **one of three cards**: two upgrade options and one in-game coin option.

#### Spin-the-wheel room

A wheel in the middle of the room awards one of:

- Healing.
- Coins.
- An upgrade choice: choose one of **two upgrade cards**.
- Trade an owned upgrade for another: choose the replacement from **three options**.
- Spawn a shopkeeper.

Prototype: one free animated spin per floor; all five outcomes have equal odds. Healing restores up to 3 HP; the coin outcome gives 20 coins. With no owned upgrade, a trade result gives 20 coins instead. A summoned shopkeeper does not create another room-entry flare reward.

#### Shop

Two columns:

| Column | Contents | Payment |
| --- | --- | --- |
| Permanent account progression | Items, keys, and other things useful at the hub, outside runs | Coins (prototype default) |
| Current-run assistance | Upgrades, healing, or coins | Dungeon flares |

Prototype prices and stock are documented in BALANCING.md: permanent keys/seals cost coins; run assistance costs flares. Purchases are finite per room per floor. Permanent items are secured immediately in device-local hub storage. These resolve earlier open questions as testable defaults, not final balance.

#### Trader and healer

Prototype: the healer restores full health once per floor; full-health visits do not spend its use. The trader exchanges one owned upgrade rank for one of three alternatives, free once per floor. Nothing is removed until confirmation.

## Combat direction

- Three-quarter top-down presentation, using Archero as a camera reference.
- Automatic ranged attacks continue **while moving**; no stop-to-shoot requirement.
- Touch uses a floating joystick wherever the player touches, excluding UI buttons.
- Ranged combat is the first implementation target.
- Melee weapons are planned for later, including upgrades that increase their range.
- The prototype uses chasing enemies, contact damage, brief hit invulnerability,
  persistent enemy state on room revisits, open doors for retreat, and restart on death.
  These are initial combat defaults, not final balance or complete progression.

## XP, levels, and upgrade choices

- Enemies drop XP.
- XP increases the player's level **for the current run**.
- On each level-up, offer three cards: **two upgrades and one coin reward**.
- The player chooses one card.
- The free upgrade room uses the same choice structure.
- Character progression across floors belongs to the same run; permanent hub
  progression is separate.

Current prototype defaults (subject to balancing):

- Normal enemies drop collectible crystals worth 2 XP; bosses drop 8 XP. Nearby crystals are attracted
  to the player with a clear path; uncollected XP stays in its room.
- Start at level 1. The next level needs `4 + 2 × (current level - 1)` XP.
- Level-up pauses combat and movement for the reward selection. Overflow XP is
  retained, and multiple earned choices are handled in sequence.
- Offers contain two distinct upgrade types and a 20-coin option. Offers stay fixed
  until selected. Coins purchase permanent shop items; run assistance uses flares.
- The pool now has 13 upgrades: damage, attack speed, movement speed, piercing, max HP/healing, critical hits, multishot, ricochet, frost, burn, XP attraction, XP gain and regeneration. Exact effects and caps are in BALANCING.md.
- Ranks stack. Prototype caps: movement 5, firing speed 8, piercing 5; damage and
  vitality remain uncapped. Capped upgrades leave the offer pool.
- Run levels, XP, coins, and upgrade ranks reset on death/restart.

Final balance, rarity, and further upgrade/weapon additions remain open.

## Dungeon flare economy

Dungeon flares are temporary currency for the current run and reset when it ends.
They purchase current-run assistance in the shop.

Let `f` be the floor number, starting at 1.

| Source | Reward | Trigger |
| --- | --- | --- |
| Initially empty room, floors 1–2 | 0 | No room reward |
| Initially empty room, floor 3 onward | `f + 2`: 5 on floor 3, 6 on floor 4, etc. | All enemies defeated, once per floor |
| Bonus room | `5 × (1 + floor((f - 1) / 5))` | First entrance per floor |
| Loot room | 10 normally; 20 when `f` is divisible by 5 | Collect loot / open chest, once per floor |
| Normal enemy | 1 | Enemy death |
| Larger enemy | 2 | Enemy death; other classifications may be added |
| Trap room | 0 | No room flare reward |
| Exit boss | `50 + 10 × (f - 1)` | Boss death |

Examples: bonus rooms give 5 on floors 1–5, 10 on 6–10, and 15 on
11–15. Bosses give 50, 60, 70, … starting on floor 1.

### Award rules and exceptions

- Room rewards are awarded once per room **per floor**. Re-entry does not reset them.
- Eligible enemies award flares once on death, separately from room rewards.
- Bonus-room flares trigger on first entrance, not on service use or purchase.
- A wheel-spawned shopkeeper cannot award another bonus-room entrance reward.
- Loot-room defenders, appearing from floor 2, award normal enemy flares in
  addition to the loot pickup's room reward.
- Enemies in initially empty rooms also award normal enemy flares in addition to
  those rooms' completion rewards.
- The boss is alone when the player enters its room.
- **Only the boss entity awards flares in the boss room.** Boss summons award
  **XP only**, with no flares or other rewards.
- Whether loot-room minibosses have a special flare value is undecided. Do not
  automatically apply the exit boss's 50-plus reward to them.
- Repeatable boss summons must not become an unlimited XP farm; the exact
  spawning/XP safeguard still needs designing.

## Hub and persistent progression

- Death returns the player to the hub.
- Some gained loot supports progression outside runs.
- Shops can offer permanent account items, keys, and hub-related purchases.
- Dungeon flares and run levels are temporary.

Prototype defaults: permanent shop purchases cost coins and are secured immediately; a key trains +1 starting HP (up to three times); a supply seal automatically provides 20 coins on the next expedition. Hub data is local to a device/browser, without account synchronization. Prices and retention can be revised during balancing.

## Hub menu and equipment inventory (current milestone)

- The hub stores unique owned item types and their permanent levels, across runs.
- Eight slots: Weapon, Armor, Headgear, Pants, Boots, Necklace, Ring, Bracelet. Four are shown on each side of the central character, above the inventory grid. Gear can be equipped, unequipped (except the weapon), crafted and upgraded from the hub.
- Starter Ranger bow; craftable Iron crossbow and Ember wand; Warden vest,
  Scout boots, Scholar necklace, Pathfinder hood, Trailguard pants, Ember ring and Archer bracelet. All gear has five permanent levels.
- Chests grant scrap equal to the floor and a 30% equipment-find chance. Duplicate
  finds grant 2 scrap. Bosses bank 3 × floor scrap once on defeat.
- Scrap and finds are secured immediately. Costs, stats and level previews are in
  BALANCING.md; these remain prototype values.
- Gear stats are copied into each new run and combine with temporary run ranks.
  Hub changes cannot alter an active run. Death removes run ranks but not equipment.
- Old local hub saves gain starter equipment without losing keys/seals/training.
  This is device-local storage, without cloud account synchronization.
- Normal enemy HP now scales 3 → 9 → 18 through floors 1–3; brutes have double HP.
  Awakened empty rooms on floor 3 use the tier-2 enemy HP of 9.

### Hub presentation and future slots

- Full-screen menu with its own original background and central dungeon doodle.
- Bottom tabs, in this exact order: Shop, Inventory, Play, Perks, Miscellaneous.
- Play selects the page; clicking the dungeon icon enters the expedition.
- Inventory replaces the former armory terminology and shows owned items below
  the character's eight active equipment slots.
- Two additional squares below the character are reserved and locked: Pet unlocks
  on first reaching floor 10; Spirit unlocks later, with no threshold set yet.
- Highest floor reached is saved permanently for future unlocks. The expedition
  remains capped at floor 3, so Pet/Spirit equipment is not implemented yet.
- Left-side events/battle pass and right-side daily/play-time rewards are deferred;
  reserve visual space without adding simulated offers or reward timers.
- Existing charm saves migrate to Necklace without losing equipment or levels.

## Replaced concepts — do not implement

- The earlier 14 × 10 and 15 × 10 map sizes.
- Walking paths becoming wall tiles.
- Used doors closing between floors.
- Protected corridors or a permanent door backbone.
- A 70%-treasure-accessibility threshold and wall-placement connectivity checks.
- Previous-run ghosts or recorded-action cooperation.
- The earlier book-writing or publishing automation project.

All rooms are accessible in the current concept; dynamic paths are no longer its mechanic.

## Open design questions and risks

These are discussion items, not approved feature requirements:

- Weapon variety, melee behaviour, enemy attacks, room dimensions, and encounter duration.
- Final art direction, audio, input adaptation, and browser/mobile performance.
- Room generation/adjacency constraints and the placement details listed above.
- Room discovery, map visibility, and how upcoming encounters are communicated.
- Whether encounters lock the player inside temporarily, and how retreat works.
- Target floor and run duration. The current balance build ends after the floor-3 boss; there is no floor 4.
- Why players would skip rooms instead of always clearing the entire floor.
- Whether five bonus rooms and early free loot create too much downtime.
- Enemy variety and new behaviours, rather than only higher HP and numbers.
- Service cycling, economy balance, coins' purpose, and anti-farming details.
- Current-run saves, cloud persistence/accounts, richer permanent progression, and monetization. Local hub saving and combat-pausing menus are implemented.

The current milestone includes all room categories and services through floor 3, including weaker enemies in initially empty rooms on floor 3. Balance this build before extending floor scaling. Fifth-floor miniboss milestones, melee, and later content remain future work.
