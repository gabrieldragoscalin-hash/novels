# Prototype tuning and testing

The expedition still ends after floor 5. These values are implementation defaults,
not claims that balance is finished. The user's economic rules and all synthesis
recipes are in [ECONOMY_SPEC.md](ECONOMY_SPEC.md).

## Reproduce and control

Use `?seed=9` on the game URL, or `godot --path . -- --seed=9`, to repeat a map.
Record seed, floor, equipped item instances/rarities/levels, perks, chosen cards,
route, health loss and currencies when reporting balance. Timing and action order
can affect later random outcomes. All neighbouring rooms remain connected.

Touch and drag to move; WASD/arrows also work. Attacks fire while moving. Walk into
doors. Tap the action button or E for chests, services and cleared boss exits.
Play in the hub is a tab; tap its dungeon icon to depart. Menus pause gameplay.

Minimap: S start, B boss, C combat, L loot, ! trap, . initially empty; purple bonus
initials identify Shop/Trader/Upgrade/Wheel/Healer. Current is gold; visited rooms
have teal outlines. All identities are shown in this prototype.

## Combat defaults

| Setting | Floor 1 | Floor 2 | Floor 3 | Floor 4 | Floor 5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Normal HP | 4 | 8 | 14 | 20 | 28 |
| Shooter HP | 3 | 6 | 10 | 15 | 21 |
| Brute HP | 10 | 20 | 32 | 46 | 64 |
| Combat enemy count (total across waves) | 4 | 5 | 6 | 7 | 8 |
| Loot defenders | 0 | 2 | 3 | 4 | 1 treasure guardian (100 HP) |
| Empty room enemies | 0 | 0 | 2 tier-2 (8 HP) | 2 tier-2 | 2 tier-3 (14 HP) |
| Boss HP | 60 | 110 | 180 | 260 | 360 |
| Normal speed | 75 | 90 | 105 | 112 | 120 |
| Hostile projectile speed | 160 | 190 | 220 | 240 | 260 |
| Shooter attack cycle | 2.4s | 2.1s | 1.8s | 1.65s | 1.5s |
| Shooter burst | 1 | 2 | 3 | 3 + fan finish | 4 + fan finish |
| Brute charge warning | 0.9s | 0.8s | 0.7s | 0.65s | 0.6s |
| Boss spread size | 3 | 5 | 7 | 7 | 9 |
| Boss flares | 50 | 60 | 70 | 80 | 90 |

### Encounter behaviors and pacing

Seven combat base rooms retain their encounter style throughout the run. Styles
are distributed so all five appear on floor 1: Mixed, Swarm, Crossfire, Heavy,
and Ambush. Start/boss overlays may temporarily override ordinary rooms later.
Swarm chasers have 65% normal HP (rounded up) and 10% extra speed. Crossfire uses
more shooters; Heavy uses brutes supported by shooters. Ambush splits the normal
floor enemy count into two waves. The second wave has a 0.9s marked warning after
the first dies; dormant enemies cannot be targeted/damaged, and count toward room
completion so loot/services/completion flares cannot be claimed early. Wave and
wounded enemy states survive revisits; doors never lock.

Shooters stop to aim for 0.65s and lock their aim direction before firing. Burst
shots are separated by 0.18s. The last burst shot becomes a two-arrow fan on floor
4 and three-arrow fan on floor 5. Initial attacks are staggered across the room.

Brutes move at 65% normal speed, warn before charging, lock direction, then charge
for up to 0.45s at 300/325/350/375/400 speed. Obstacles stop charges. Recovery lasts
0.85s with no movement or contact attack. A 2.3s pursuit phase follows recovery.

Boss floor 1 alternates spread/charge; floor 2 adds ground zones; floors 3–5
combine spreads and ground zones, with 25% shorter pursuit cooldowns
below half HP (shown with an orange ring). Ground attacks lock 2/3/4/5 locations
on floors 2–5, warn for 0.9s and strike once. Bosses still start alone. Treasure
guardians alternate charge and a three-shot spread, have 100 HP, give 4 XP/2
flares, and never pay boss/floor rewards. Their chest remains blocked until defeat.

Boss access remains immediate. Exploration provides XP choices, healing, services
and improved loot; no room-clear quota or temporary boss key has been added.
Prototype pacing goals: combat rooms about 10–20s, bosses about 30–60s with a
plausible build; roughly 5–8 minutes through floor 3 with some exploration. Floors
4–5 extend that test window. These are targets to measure, not verified clear-time
claims. Test with a common level-1 weapon, no other gear/perks and god mode off.
Record the build as weapons, cards and persistent perks can greatly change DPS.
The HUD now shows active expedition time, excluding hub/cards/services/cheats,
transitions and focus loss. The floor-5 boss ends the run; floor 6 is disabled.

Starter Common bow level1: 1 damage, 0.45s firing interval, movement185, HP6.
Equipment and perks modify these values. Contact/projectiles deal 1 damage;
hit immunity lasts 1s, arrival protection 0.7s. Bosses telegraph for 0.65s.
Pillars block ordinary attacks. Boss death clears hostile projectiles and ground hazards.

Normal enemies give 2 XP, bosses 8. Levels require 4,6,8,... XP. Coin choice:20.
The XP magnet starts at radius110. Rarity multipliers and enhancement are defaults:
Common1, Uncommon1.15, Rare1.35, Epic1.7, Legendary2.3, Mythic3.6, with +0.25 per
synthesis enhancement. Weapons additionally gain +1 damage per enhancement;
health-bearing equipment gains +1 HP per enhancement. Base item levels remain1–5.

Weapon-specific attacks, card eligibility, rank caps and interaction tuning are
in [WEAPONS_SPEC.md](WEAPONS_SPEC.md). Wall ricochet and the old status cards have
been replaced. Fractional XP and damage are retained; individual projectiles
cannot hit the same enemy twice. Wands/See All bypass pillars; other attacks do not.

## Economy defaults

- Coins persist across runs. Flares reset on a new run, carrying across floors.
- Dungeon loot coins:20/25/30/35/40 across floors 1–5. Every chest gives one item.
  Common/Uncommon/Rare/Epic odds: floor1 80/20/0/0%; floor2 70/28/2/0%;
  floor3 55/40/5/0%; floor4 40/50/10/0%; floor5 0/70/28/2%.
  Floors2–5 also offer a run-upgrade/coin choice. Loot flares are10 normally,
  20 on floor5, plus eligible defender kill flares.
- Dungeon loot key chance5%; conditional types70% Copper /25% Silver /5% Gold.
- Normal enemies have a2% chance to leave a Common equipment pickup. Collect it by
  approaching within32 units. It stays in the room if uncollected.
- Daily hub offers refresh at00:00 UTC: five matching parts for50 coins each, and
  three Common item copies for150 coins each. Each offer sells once per day.
- Part leveling costs5 × current item level, only from the matching category.
  It does not consume item copies or coins directly. No scrap/crafting remains.
- Floor keys: see exact reward table/formula in ECONOMY_SPEC.md. Three paying
  clears per day PER FLOOR, saved across reloads. No third key source was invented.
- Chest prices: one matching key OR60/200/500 gems for Copper/Silver/Gold.
  Gem earning/tasks/purchases are reserved, so normal new profiles have0 gems.
- Copper odds55/35/9/1/0%; Silver38/32/26/3.5/0.5%; Gold15/20/45/16/4%, ordered
  Common/Uncommon/Rare/Epic/Legendary. On ordinary Gold legendary drops,10% are+1.
- Pity: Copper Epic, Silver Legendary, Gold Legendary+1 at35 after34 misses.
  Normal Gold legendary ALSO resets pity. Counters are saved separately by chest
  type and shared between key/gem payment methods. Odds/guarantees are shown in UI.
- Perks start250 coins, +50 per purchase. First unlock: Starting upgrade, two upgrade
  choices without a coin card. All four known perks must unlock before leveling;
  the other eight are reserved. HP:+1 per level, dodge:+1 percentage point per
  level, boss damage:+2 percentage points per level. Limits1/25/25/25.

Daily limits currently use the device clock; no server anti-tamper guarantee or
cloud synchronization is claimed. All exact odds/prices/effects above can be tuned.

## Room services and traps retained

Healer:full heal once per floor. Free upgrade:two upgrades/20coins once. Trader:
one rank for one of three eligible choices once. Wheel:one equal-probability spin
among heal3,20coins,two-upgrade choice,trade,shopkeeper; no trade available gives
20coins. Wheel shops never repeat bonus entrance flares.

Dungeon-room shop remains separate from hub shop: Common bow/armor copies150coins;
run upgrade choice20flares,heal3HP10flares,20coins10flares, each once per room/floor.
It no longer sells generic keys or seals. Floor advancement refreshes finite stock.

Traps first trigger after1s, then every2.5s. Slow field:35% slow4s within radius100;
spikes:1 damage within80; volley:three downward shots, visible lane warning.
Trap types change between floors. Initially empty rooms award5 room flares on
floor3 after clearing, in addition to their enemy rewards.

## Inventory and persistence

Eight slots surround the character (four per side), plus locked Pet/Spirit spaces.
Pet milestone:first reach10; Spirit threshold remains undefined. Inventory shows
INDIVIDUAL copies. Synthesis keeps the item grid below a base/ingredient workspace,
ordered highest rarity first and grouped by duplicates. Exact recipe counts,
identity/category rules, and stages are documented in ECONOMY_SPEC.md.

Part levels, synthesis rarity and enhancement are distinct. Equipped ingredient
copies are protected; the chosen base can be equipped and retains its ID/level.
A preview shows the resulting stage and consumption before committing.

Atomic version4 saves include wallet, instances, equipped UIDs, parts, keys, pity,
perks, shop day/stock and daily floor counts. Existing prototype gear levels and
necklace migration are preserved. Retired unsupported resources are archived in
`legacy_data`, without invented conversion rates. Clearing site data removes local
progress. Current runs are not saved; stored progress and coins survive death.

## Tuning locations

- `scripts/economy.gd`: odds, prices, floor-key formula, synthesis recipes, policy.
- `scripts/hub.gd`: transactions, individual inventory, save migration, daily limits.
- `scripts/hub_menu.gd`: shop, inventory, synthesis, perks, reserved gem UI.
- `scripts/equipment.gd`: templates, item-level and rarity stat defaults.
- `scripts/dungeon.gd`: room composition, enemies, floor limit.
- `scripts/enemy_ai.gd`: pursuit, bursts, charge/recovery and boss patterns.
- `scripts/weapons.gd`, `combat.gd`, `progression.gd`, `services.gd`: run combat/rewards.

Tests cover all synthesis recipes, duplicate identity, rejection without partial
consumption, floor-key limits across reloads/days, pity and normal-gold resets,
wallet spending, perk unlock order/caps, room rules, and actual boss combat.

The floor-4/5 numbers and improved loot odds extend the accepted floor-1/2/3
balance proposal and remain tuning defaults. All ordinary enemy and boss hits
still deal 1 damage; increased difficulty comes from patterns and pressure.
