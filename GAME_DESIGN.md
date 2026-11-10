# Game Design — Working Document

Last updated: 2026-11-10

Status: pre-production. This records the agreed concept, not an implemented game.
No title or engine has been selected. Open decisions below must not be treated as
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
costs. Store releases, monetization, and the engine are undecided.

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

Which specific resources and purchases survive death is not yet defined.

## Dungeon structure

- Grid: **5 × 5**, with coordinates **A–E** and **1–5**.
- All rooms remain accessible. **No doors close and no paths turn into walls.**
- The dungeon's room layout and base identities persist between floors in a run.
- A new run generates a new random layout.
- Room adjacency/generation constraints will be designed later.
- Movement between neighbouring rooms is understood as orthogonal; exact
  movement, combat, camera, and control systems remain undecided.

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

Open generation details:

- How the middle row/column of the odd-sized grid participates in opposite halves.
- How corners select their starting edge and whether a minimum S-to-E distance applies.
- Whether the exit must always move, rather than only being reselected each floor.
- Base identities beneath the initial start and exit, which become relevant when
  those roles move elsewhere.

## Room identities and floor progression

### Combat rooms

Remain combat rooms, with increasing encounter difficulty across floors. Enemy
types, counts, scaling, and larger-enemy classifications are not yet defined.

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
- Trap behaviours, damage/debuffs, and counterplay are not yet defined.

### Bonus rooms

Five permanent bonus-room locations, with these five service roles:

1. Shop.
2. Trader.
3. Free upgrade.
4. Spin-the-wheel room.
5. Healer.

Each location cycles through all five roles before repeating, returning to the
same role every five floors. Every floor must contain one of each service.
The rotation order is undecided; independently shuffling each room must not
accidentally remove or duplicate services.

#### Free upgrade

Choose **one of three cards**: two upgrade options and one in-game coin option.

#### Spin-the-wheel room

A wheel in the middle of the room awards one of:

- Healing.
- Coins.
- An upgrade choice: choose one of **two upgrade cards**.
- Trade an owned upgrade for another: choose the replacement from **three options**.
- Spawn a shopkeeper.

Wheel odds, number of spins, costs, and what happens when a trade is rolled without
an owned upgrade are undecided. A summoned shopkeeper does not create another
room-entry flare reward.

#### Shop

Two columns:

| Column | Contents | Payment |
| --- | --- | --- |
| Permanent account progression | Items, keys, and other things useful at the hub, outside runs | Undecided |
| Current-run assistance | Upgrades, healing, or coins | Dungeon flares |

Prices, stock, purchase limits, and when permanent purchases become secured are
deferred. Do not assume coins pay for either column.

#### Trader and healer

Their presence and service identities are agreed. Detailed offers, costs, healing
amounts, and interaction limits remain undecided. The wheel's upgrade-exchange
reward does not yet establish the standalone trader's full behaviour.

## XP, levels, and upgrade choices

- Enemies drop XP.
- XP increases the player's level **for the current run**.
- On each level-up, offer three cards: **two upgrades and one coin reward**.
- The player chooses one card.
- The free upgrade room uses the same choice structure.
- Character progression across floors belongs to the same run; permanent hub
  progression is separate.

Upgrade pools, stacking rules, rarity, XP thresholds, coin amounts, and the broader
purpose of coins remain undecided.

## Dungeon flare economy

Dungeon flares are temporary currency for the current run and reset when it ends.
They purchase current-run assistance in the shop.

Let `f` be the floor number, starting at 1.

| Source | Reward | Trigger |
| --- | --- | --- |
| Initially empty room, floors 1–2 | 0 | No room reward |
| Initially empty room, floor 3 onward | `f + 2`: 5 on floor 3, 6 on floor 4, etc. | Room completion; exact completion condition to define |
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

The retained loot types, hub functions, permanent-item payment, death retention,
and any extraction requirements are deliberately deferred.

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

- Combat perspective, controls, attacks, weapons, room dimensions, and encounter duration.
- Engine, art direction, audio, input adaptation, and browser/mobile performance.
- Room generation/adjacency constraints and the placement details listed above.
- Room discovery, map visibility, and how upcoming encounters are communicated.
- Whether encounters lock the player inside temporarily, and how retreat works.
- Target floor duration, typical run duration, and any final floor or ending.
- Why players would skip rooms instead of always clearing the entire floor.
- Whether five bonus rooms and early free loot create too much downtime.
- Enemy variety and new behaviours, rather than only higher HP and numbers.
- Service cycling, economy balance, coins' purpose, and anti-farming details.
- Persistence, saves, pause/resume, permanent progression, and monetization.

A suggested next step is a small playable prototype spanning three floors, testing
combat feel, route choices, room revisits, and pacing before expanding content.
This is a recommendation, not a separately agreed implementation scope.
