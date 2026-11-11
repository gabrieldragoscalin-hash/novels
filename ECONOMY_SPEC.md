# Economy revision — user rules

This supersedes the scrap/crafting/key-training prototype. Scrap is not a game
currency. Equipment is found in dungeons or opened from shop chests. Item copies
are stored separately; duplicates are never automatically converted.

## Wallet, keys and daily shop

- Shop currencies: coins, gems and copper/silver/gold keys. Gem earning, tasks, and gem purchases are reserved until defined. The wallet and
  chest payment path exist, but no gems are granted or sold in this build.
- Dungeon loot chests have a low chance to award keys.
- Each floor awards its key reward for the first THREE clears of that floor per
  day, independently of all other floors. Further clears still progress the run.
- Floor rewards: 1 copper; 1 silver; 2 copper; 2 silver; 1 gold on floors 1–5.
  Floors 6–9 alternate 3 copper / 3 silver; floor 10 gives 2 gold. Floors 11–14
  alternate 4 copper / 4 silver; floor 15 gives 3 gold, continuing this pattern.
  Confirmed: floor 6 starts with copper, then silver/copper/silver.
- Six coin offers rotate every 24 hours: armor parts (armor/headgear/pants/boots),
  accessory parts (bracelet/necklace/ring), weapon parts, and three random COMMON
  item copies. Exact prices, quantities, and refresh timing were not specified.
- Parts upgrade item levels. Synthesis upgrades rarity/enhancement; these are
  separate operations, not a return of scrap crafting.

## Shop chest odds and pity

Exact percentages are tuning defaults, not user-specified numbers. Required order:
Copper favours grey/green, with less blue and very little purple. Silver still
frequently drops grey/green, more blue than copper, slightly more purple, and very
little yellow. Gold favours blue, has better purple/yellow odds, and can award a
yellow +1 directly. Mythic is not in any current chest pool.

Each chest type has its own saved pity counter, shared between payment methods:
- Copper: after 34 opens without purple, opening 35 is guaranteed purple.
- Silver: after 34 without yellow, opening 35 is guaranteed yellow.
- Gold: after 34 without ANY yellow, opening 35 is guaranteed yellow +1.
  BOTH normal yellow and yellow +1 reset the gold counter to zero.

## Synthesis — base plus additional ingredients

| Base | Required additional copies | Result |
| --- | --- | --- |
| Grey | 3 grey of exact same item | Green |
| Green | 3 green of exact same item | Blue |
| Blue | 3 blue of exact same item | Purple |
| Purple | 2 purple of same category/slot | Purple +1 |
| Purple +1 | 1 purple +1 of exact same item | Yellow |
| Yellow | 2 yellow of same category/slot | Yellow +1 |
| Yellow +1 | 2 unenhanced yellow of same category/slot | Yellow +2 |
| Yellow +2 | 1 yellow +2 of exact same item | Bright-orange Mythic |

"Three other" means FOUR total including the selected base. Category means the
equipment slot (e.g. any weapon for purple/yellow category recipes). Matching
stages must match rarity AND enhancement; yellow +1 cannot fill a plain-yellow
ingredient slot. Mythic is the current end of the synthesis chain.

Inventory has a Synthesis button. This mode retains the item grid, sorted by
rarity descending and grouped by duplicates. The character/loadout area is replaced
by a top-left base-item slot and ingredient slots revealed after selecting a base.
The base remains equipped if it was equipped; equipped items cannot be consumed as
additional ingredients. Preview the result and consumed copies before committing.

## Perks

Twelve slots, initially locked. First purchase ALWAYS unlocks Starting upgrade at
level 1 (its only level). Other unlocks are random and arrive at level 1. No perk can level until all four defined perks are unlocked. The other eight slots
remain reserved and do not block leveling (confirmed user clarification).

Defined: Starting upgrade (1 level), Starting HP (25), Dodge chance (25), Boss
damage (25). Eight slots are undecided and remain reserved; they neither grant invented effects
nor block leveling of the four defined perks.

Purchases start at 250 coins and increase each purchase. Exact increment and
per-level effects were not specified. No undefined perk effects should be invented.

## Migration

Keep all existing equipment and item levels. Convert the old unique-item save into
individual copies, retaining equipped identities. Retired scrap, old generic keys,
seals and key-training data should be archived in the save, not silently exchanged
for arbitrary new currencies. Save the new wallet, daily counters, pity counters,
individual copies, parts, perk purchases and progress together atomically.

The dungeon is now playable through floor 5; floor 6+ remains disabled.
Daily floor rewards include floor 4: two silver keys, floor 5: one gold key.

## Current tuning defaults (not specified by the user)

- Daily shop: 5 parts for 50 coins per category; each common copy costs 150 coins.
  Each of the six offers can be bought once per UTC day, refreshing at midnight UTC.
- Chests cost one matching key OR 60/200/500 gems for copper/silver/gold. Gem
  acquisition is reserved; gem transactions are tested using isolated fixtures.
- Copper odds: common 55.5%, uncommon 35%, rare 9%, epic 0.5%.
- Silver: common 39.2%, uncommon 32%, rare 26%, epic 2.5%, legendary 0.3%.
- Gold: common 17.5%, uncommon 22%, rare 45%, epic 13%, legendary 2.5%.
  On a non-pity legendary gold drop, 10% are +1 (0.25% of ordinary gold opens).
- When equipment drops, floor-1 rarity odds are80% common /20% uncommon; later
  floors improve rarity odds as listed in BALANCING.md. All loot chests have a
  5% key chance; conditional key odds are 70% copper / 25% silver / 5% gold.
  Normal enemies have a 2% chance to leave a common item pickup on the floor.
- Item-level upgrades retain the current level-5 cap and cost 5 × current level
  matching parts, without consuming duplicates. No crafting recipes remain.
- Perk price is 250 + 50 × previous purchases. Starting HP adds 1 per level;
  dodge adds 1 percentage point per level; boss damage adds 2 percentage points
  per level. Starting upgrade offers two upgrades, without a farmable coin card.
- Coins are now a persistent wallet, including run rewards. Flares remain temporary
  and retain their existing role in the separate dungeon-room shop. Dungeon shops
  no longer sell keys or seals; their permanent offers are common item copies.
- UTC reset uses the device clock until an authoritative backend is introduced.
  The implementation does not claim anti-tamper protection or cloud account sync.

## Quick synthesis and ingredient filtering

Common, Uncommon and Rare all require three other copies of the exact same item.
After selecting a base, show only eligible ingredients in the inventory grid;
the base remains in the upper slot and can be cleared there. Selected ingredients
remain visible and can be removed with a tap or through the upper slots.
Quick synthesis cascades Common→Uncommon→Rare→Epic until no eligible groups remain.
Rare bases are included; Epic bases and higher are never consumed automatically.
Equipped copies are protected as ingredients, and equipped/highest-level bases are
preferred. Lowest-level ingredients are used first. No coins or parts are charged.

Loot-room equipment is now conditional:35/40/45/50/65% on floors1–5. Chest rarity
weights apply only after that item roll succeeds. Existing non-equipment rewards
remain. Full account reset is available in Cheats with a confirmation; it clears
all currencies, copies, levels, perks, counters and progress on this device.
