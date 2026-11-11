# Prototype tuning and testing

The expedition still ends after floor 3. These values are implementation defaults,
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

| Setting | Floor 1 | Floor 2 | Floor 3 |
| --- | ---: | ---: | ---: |
| Normal/shooter HP | 3 | 9 | 18 |
| Brute HP | 6 | 18 | 36 |
| Combat enemy count | 3 | 4 | 5 |
| Loot defenders | 0 | 2 | 3 |
| Initially empty room enemies | 0 | 0 | 2 tier-2 normals, 9 HP |
| Boss HP | 22 | 38 | 54 |
| Boss spread shots | 3 | 5 | 5 |
| Boss flares | 50 | 60 | 70 |

Starter Common bow level1: 1 damage, 0.45s firing interval, movement185, HP6.
Equipment and perks modify these values. Contact/projectiles deal 1 damage;
hit immunity lasts 1s, arrival protection 0.7s. Bosses telegraph for 0.65s.
Pillars block ordinary attacks. Boss death clears hostile projectiles.

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
- Dungeon loot:20/25/30 coins by floor, existing room flares, an item copy with
  80% Common /20% Uncommon odds. Floors2–3 also offer a run-upgrade/coin choice.
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
- `scripts/weapons.gd`, `combat.gd`, `progression.gd`, `services.gd`: run combat/rewards.

Tests cover all synthesis recipes, duplicate identity, rejection without partial
consumption, floor-key limits across reloads/days, pity and normal-gold resets,
wallet spending, perk unlock order/caps, room rules, and actual boss combat.
