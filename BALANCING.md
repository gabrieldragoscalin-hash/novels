# Three-floor balance build

This is the complete **ranged, three-floor prototype**, not a balanced release.
Defeating floor 3 ends the expedition; there is no floor 4. Melee and the fifth-floor
miniboss milestones remain future work.

## Reproduce a run

Open `https://gabrieldragoscalin-hash.github.io/novels/?seed=9` to repeat a layout.
Omit the seed for a fresh random map each run. The seed appears below the room.
The same seed and action sequence reproduce room placement, floor changes, and
upgrade offers. Different purchases/choices can change later random outcomes.
Local hub training and supply seals also affect starting strength.

Native equivalent: `godot --path . -- --seed=9`.

Record the seed, floor, starting hub training, route, chosen upgrades, health lost,
coins/flares earned and spent, and approximate floor duration when reporting balance.
These automated tests establish functioning rules, **not fair difficulty**.

## Controls and map

Touch and drag anywhere except buttons; WASD/arrows also work. Walk into a doorway
to travel. The action button (or E) opens cleared chests/services or descends after
boss victory. Doors stay open for retreat. Services and reward choices pause play.

Minimap: **S** start, **B** boss (red), **C** combat, **L** loot, **!** trap,
**.** initially empty; bonus initials are **S** shop, **T** trader, **U** upgrade,
**W** wheel, **H** healer. The start has a teal background; shops are purple.
The current room is gold and visited rooms have teal outlines. All identities are
shown for this balance build, without a discovery system.

## Generation

Floor 1: 1 start, 1 boss, 5 bonus, 7 combat, 3 empty, 4 loot, 4 traps.
The two initial S/B locations have an underlying empty identity. Later S/B roles
move, so visible counts of ordinary room types can change. Bonus rooms are never
overridden. Starts are on an edge and must move; bosses are in the opposite half
and must move. For a five-cell axis, the middle row/column is excluded from the
opposite-half destination selection. Corners retain their selected starting edge.

Room identities stay fixed across floors. Floor state (enemies, rewards, shop
stock, uses, and visits) refreshes. Bonus services rotate together through all five
roles, with one of each per floor. Trap types never repeat on adjacent floors.
Room adjacency constraints have not been added; all neighbouring rooms connect.

## Combat defaults

| Setting | Floor 1 | Floor 2 | Floor 3 |
| --- | ---: | ---: | ---: |
| Normal/shooter HP | 3 | 5 | 7 |
| Brute HP | 6 | 10 | 14 |
| Combat room enemy count | 3 | 4 | 5 |
| Loot room enemy count | 0 | 2 | 3 |
| Initially empty room enemies | 0 | 0 | 2 normal, tier 2 (5 HP) |
| Boss HP | 22 | 38 | 54 |
| Boss spread | 3 shots | 5 shots | 5 shots |
| Boss flare reward | 50 | 60 | 70 |

Player: 6 starting HP plus hub training; 185 movement speed; 1 damage;
one shot per 0.45 seconds. Contact and hostile projectiles deal 1 damage, with
one second of invulnerability after a hit and 0.7 seconds of safe arrival time.

Normal enemies chase. Brutes are slower and tougher. Shooters reposition until
they have a clear shot and keep distance. Bosses chase slowly and telegraph their
spread for 0.65 seconds. Pillars block both sides' shots. Bosses begin alone; no
summons are currently implemented, but any future boss-room adds are XP-only.
Enemy health/deaths, unopened chests, uncollected XP, and service uses survive
room revisits. Boss death clears hostile projectiles.

Enemies give 2 XP; bosses give 8 XP. Levels require 4, 6, 8, ... XP.
Level-up offers two distinct upgrades or 20 coins. Current upgrades stack:
+1 damage; 15% faster firing; +10% base movement; +1 enemy pierced; +2 max HP
and heal 2 HP. Movement caps at 5 ranks, firing at 8, piercing at 5.

## Rewards and services

HUD **C** means coins; **F** means dungeon flares. Both carry across floors and
reset on a new run. Shops make coins and flares useful now.

- Normal/shooter kill: 1 flare. Brute kill: 2. Boss: its floor reward only.
- Loot chest: 10 flares once, plus 20/25/30 coins by floor. Floors 2–3 also give
  an upgrade-or-coins choice. Defenders give their own XP/flares.
- Initially empty room: no room reward on floors 1–2. Floor 3: 5 flares once when
  its enemies are defeated, in addition to their individual kill rewards.
- Bonus room: 5 flares on first entrance each floor, independent of service use.
- Trap room: no flare reward.
- Healer: full heal once per floor; visiting at full health does not consume it.
- Free upgrade: two upgrades or 20 coins, once per floor, without increasing level.
- Trader: surrender one owned upgrade rank for one of three other upgrades,
  once per floor. Nothing is removed until confirmation. Offers stay fixed for
  each surrendered type. At least three eligible replacements must exist.
- Wheel: one animated spin per floor. Five equally likely results: heal 3 HP;
  20 coins; choose between two upgrades (no coin card); trade one upgrade for one
  of three; summon a shopkeeper. If there is no eligible trade, that result gives
  20 coins. Summoned shops do not repeat the room's entrance flare reward.
- Shop: finite stock per room per floor, including a wheel shop. Left column:
  hub key for 20 coins, supply seal for 40 coins. Right column: upgrade choice for
  20 flares, heal 3 HP for 10 flares, 20 coins for 10 flares. Full-health healing
  purchases are rejected without payment.

Shop stock and wheel/trader/healer uses all reset on floor advancement.
No resources or enemies respawn through room re-entry.

## Trap defaults

Traps activate one second after entry, then every 2.5 seconds. Slow fields apply
four seconds of 35% movement reduction within radius 100. Spikes deal one damage
within radius 80. Volleys fire three downward shots with visible lane warnings.
Centre circles/lanes pulse before activation. Pillars offer cover for volleys.
Each trap location chooses a different type on the next floor.

## Hub defaults and persistence

These are **prototype choices for previously undecided systems**:

- Permanent shop items are paid for with coins and secured immediately, including
  if the player dies later. This provides a reason to choose coins over upgrades.
- A key buys +1 starting HP at the hub, up to three permanent training levels.
- A supply seal is consumed automatically when starting the next run and gives
  20 starting coins. The hub displays this before departure.
- Keys, seals, and training save locally to `user://hub.json` (browser storage for
  the web build). There is no login, cross-device synchronization, or cloud account.
  Clearing site data removes this local progress; current-run state is not saved.
- Death, completion, or the Return to hub button leads back to preparation. Health,
  XP, levels, ranks, coins, and flares are reset when the next expedition begins.

## Main tuning locations

- `scripts/dungeon.gd`: room counts, generation, encounter HP/counts, floor limit.
- `scripts/combat.gd`: attacks, damage, AI, projectile speeds, trap effects, rewards.
- `scripts/progression.gd`: XP thresholds, upgrade effects, caps, coin card reward.
- `scripts/services.gd`: finite rewards, shop prices, healing, trading.
- `scripts/hub.gd`: local progression and save validation.

Before scaling beyond floor 3, check whether players have reasons to skip rooms,
whether each currency/upgrade choice is useful, whether boss patterns are readable,
and whether floors 2–3 remain viable without clearing every room.
